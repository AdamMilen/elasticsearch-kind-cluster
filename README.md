# elasticsearch-assignment
In a Nix shell environment, you can immediately use any program packaged with Nix, without installing it permanently. <br />
Every command will be executed within nix shell. <br />

Multi-user installation <br />
Downloading Nix on WSL2 Windows <br />
`sh <(curl -L https://nixos.org/nix/install) --daemon` <br />

Downloading on MacOS <br />
`sh <(curl -L https://nixos.org/nix/install)` <br />


git clone the repo <br />
Enter the repo folder and run the following commands: <br />
`nix-shell` <br />
`kind create cluster --name=elastic-linkerd --config=kind-config.yaml` <br />



Check if kind cluster created <br />
`kubectl get no`

# Initial setup
Run `./initial_setup.sh` <br />
This script installs argocd and linkerd on kind cluster. <br />

deploying system application and user applications using app of apps pattern <br />
1. `kubectl apply -f ./argocd/root-system-apps.yaml`
2. `kubectl apply -f ./argocd/root-user-apps.yaml`


changing elastic built-in user password <br />
wait for elasticsearch application to be healthy then execute the command below <br />
`kubectl exec -c elasticsearch -it elastic-linkerd-es-default-0 -n elastic-system -- elasticsearch-users passwd elastic -p adminadmin` <br />
This will ensure elasticsearch-exporter can connect to the elasticsearch instance. <br />



edit /etc/hosts <br />
127.0.0.1 nginx.elasticsearch.local <br />
This will let you enter nginx.elasticsearch.local in the url. <br />


## Manual way ##

# argocd installation
install argocd <br />
kubectl create ns argocd kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml <br /> <br />

get argocd password <br />
argocd admin initial-password -n argocd kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d <br /> <br />

port forward and login through cli <br />
kubectl port-forward -n argocd service/argocd-server 8443:443 & argocd login localhost:8443 <br /> <br />

add repo git <br />
token=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 argocd repo add https://github.com/AdamMilen/elasticsearch-assignment.git --username AdamMilen --password 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 <br /> <br />

# install nginx ingress controller
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml


# Install ECK operator
kubectl create -f https://download.elastic.co/downloads/eck/2.16.1/crds.yaml <br />
linkerd inject https://download.elastic.co/downloads/eck/2.16.1/operator.yaml | kubectl apply -f - <br />
kubectl apply elasticsearch.yaml <br />

# changing elastic built-in user password
kubectl exec -c elasticsearch -it elastic-linkerd-es-default-0 -n elastic-system -- elasticsearch-users passwd elastic -p adminadmin <br />

You can port forward elasticsearch service <br />
kubectl port-forward service/quickstart-es-http 9200 <br />

# Install Prometheus Operator (grafana & Alertmanager included)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts <br />
helm repo update <br />

helm install kind-prometheus --namespace monitoring --create-namespace prometheus-community/kube-prometheus-stack -f argocd/system-apps-applications/values-prom-operator.yaml <br />

# Installing prometheus exporter and setting the correct ClusterIP and without cert check
helm install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter -f argocd/system-apps-applications/values-elasticsearch-exporter.yaml <br />


# Connecting exporter to Prometheus: configuring servicemonitor
kubectl apply -f servicemonitor.yaml <br />

# Linkerd installation
linkerd check --pre <br />
linkerd install --crds | kubectl apply -f - <br />
linkerd install | kubectl apply -f - /n <br />

# port-forward grafana
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kind-prometheus" -oname) <br />

kubectl --namespace monitoring port-forward $POD_NAME 3000 & <br />

# port-forward prometheus
kubectl port-forward svc/prometheus-operator-kube-p-prometheus -n monitoring 9090:9090 & <br />

# Alerts for elasticsearch
In order to prevent disks from filling up in the future and act proactively, you should create alerts based on **disk usage that will notify you when the disk starts filling up**.

Think about adding recording rules, recording rules are essential for optimizing the performance of your Prometheus setup. As your environment grows, the number of metrics and complexity of queries increases. Running complex queries in real-time can become slow and resource-intensive.

# setting up alerts to slack
https://medium.com/@joudwawad/comprehensive-beginners-guide-to-kube-prometheus-in-kubernetes-monitoring-alerts-integration-4ade4fa8fa8c

https://hooks.slack.com/services/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