# elasticsearch-assignment

copy shell.nix to your working directory
run nix-shell
run kind create cluster --name=multi-node-cluster --config=kind-config

# check if kind cluster created
kubectl get no

# install argocd
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward -n argocd service/argocd-server 8443:443

# Install ECK operator
kubectl create -f https://download.elastic.co/downloads/eck/2.16.1/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.16.1/operator.yaml

kubectl apply elasticsearch.yaml
kubectl port-forward service/quickstart-es-http 9200

# Install Prometheus Operator (grafana & Alertmanager included)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kind-prometheus --namespace monitoring --create-cluster prometheus-community/kube-prometheus

# Installing prometheus operator and setting the correct ClusterIP and without cert check
helm install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter --set es.uri="https://elastic:x42vf8y18CngC4L4u15X1oiy@quickstart-es-http:9200" --set es.sslSkipVerify=true

# Adding scrape config
kubectl edit kind-prometheus-kube-prome-prometheus -n monitoring