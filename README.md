# elasticsearch-assignment

copy shell.nix to your working directory
nix-shell
kind create cluster --name=elastic-linkerd --config=kind-config.yaml

# check if kind cluster created
kubectl get no

# install argocd
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward -n argocd service/argocd-server 8443:443

# install nginx ingress controller
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml


# Install ECK operator
kubectl create -f https://download.elastic.co/downloads/eck/2.16.1/crds.yaml
linkerd inject https://download.elastic.co/downloads/eck/2.16.1/operator.yaml | kubectl apply -f -

kubectl apply firerealm-secret.yaml
kubectl apply elasticsearch.yaml

# adding user devops
kubectl exec -c elasticsearch -it elastic-linkerd-es-default-0 -- sh
elasticsearch-users passwd elastic -p adminadmin

kubectl port-forward service/quickstart-es-http 9200

# Install Prometheus Operator (grafana & Alertmanager included)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kind-prometheus --namespace monitoring --create-namespace prometheus-community/kube-prometheus-stack -f values-prom-operator.yaml

# Installing prometheus exporter and setting the correct ClusterIP and without cert check
helm install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter -f values-elasticsearch-exporter.yaml

# Connecting exporter to Prometheus: option 1, Adding scrape config
kubectl edit prometheus kind-prometheus-kube-prome-prometheus -n monitoring

kubectl create secret generic additional-scrape-configs --from-file=prometheus-additional.yaml --dry-run=client -oyaml > additional-scrape-configs.yaml

kubectl apply -f additional-scrape-configs.yaml -n monitoring

# Connecting exporter to Prometheus: option 2, configuring servicemonitor
kubectl apply -f servicemonitor.yaml

# edit prometheus instance to matchlabel servicemonitor (release=kind-prometheus)
kubectl edit prometheus kind-prometheus-kube-prome-prometheus -n monitoring

# port-forward grafana
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kind-prometheus" -oname)

kubectl --namespace monitoring port-forward $POD_NAME 3000 &

# port-forward prometheus
kubectl port-forward svc/kind-prometheus-kube-prome-prometheus -n monitoring 9090:9090 &

# Alerts for elasticsearch
In order to prevent disks from filling up in the future and act proactively, you should create alerts based on **disk usage that will notify you when the disk starts filling up**.

Think about adding recording rules, recording rules are essential for optimizing the performance of your Prometheus setup. As your environment grows, the number of metrics and complexity of queries increases. Running complex queries in real-time can become slow and resource-intensive.

# setting up alerts to slack
https://medium.com/@joudwawad/comprehensive-beginners-guide-to-kube-prometheus-in-kubernetes-monitoring-alerts-integration-4ade4fa8fa8c

https://hooks.slack.com/services/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