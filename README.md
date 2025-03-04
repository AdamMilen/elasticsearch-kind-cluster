# Elasticsearch cluster project

This project sets up an Elasticsearch cluster with monitoring, logging, and alerting using Kubernetes, ArgoCD, and Prometheus within a Nix shell ephermal environment.

---

## Prerequisites

### Install Nix (Multi-user installation)

#### On WSL2 (Windows):

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

#### On macOS:

```sh
sh <(curl -L https://nixos.org/nix/install)
```

- Open a new terminal and navigate to the repository folder.
- Ensure **Docker Desktop** is running for the Kind cluster to function properly.

#### Uninstalling nix:
[link](https://nix.dev/manual/nix/2.21/installation/uninstall)

---

## Getting Started

1. **Checkout the development branch:**
   ```sh
   git checkout dev
   ```
2. **Enter Nix shell:**
   ```sh
   nix-shell
   ```
3. **Set up costum prompt:**
   ```sh
   PS1="$ "
   ```
4. **Create a Kind cluster:**
   ```sh
   kind create cluster --name=elastic-linkerd --config=kind-config.yaml
   ```
5. **Verify cluster creation:**
   ```sh
   kubectl get no
   ```

---

## Initial Setup

1. **Make the setup script executable:**

   ```sh
   chmod +x ./initial_setup.sh
   ```

2. **Run the script:**

   ```sh
   ./initial_setup.sh
   ```

   - This installs ArgoCD and Linkerd on the Kind cluster.
   - You may be prompted for inputs during execution—stay attentive.
   - Check the last output after the script is done, includes argocd credentials and linkerd dashboard.
   - ignore grafana dashboard from linkerd

3. **Deploy applications using the App of Apps pattern:**

   **Deploy system applications (Prometheus Operator and Ingress):**

   ```sh
   kubectl apply -f ./argocd/root-system-apps.yaml
   ```

   *(Takes \~5 minutes, make sure all apps are healthy. Only ingress service progressing)*
   *If the ingress controller pod takes more than 6 minutes to be ready, delete it and k8s will deploy again*

   **Deploy user applications (ECK Operator, Elasticsearch, Exporter, and Alerts):**

   ```sh
   kubectl apply -f ./argocd/root-user-apps.yaml
   ```

   *(Takes \~3 minutes)*

4. **Access ArgoCD UI:**

   - [ArgoCD Dashboard](http://localhost:8443)

---

## Elasticsearch Configuration

### Change the Elasticsearch Built-in User Password

- **Wait until Elasticsearch is healthy**, then run:
  ```sh
  kubectl exec -c elasticsearch -it elastic-linkerd-es-default-0 -n elastic-system -- elasticsearch-users passwd elastic -p adminadmin
  ```
  *(This ensures the Elasticsearch Exporter can connect to the instance.)*
  *Ignore the warning*

---

## Monitoring Setup

### Port Forwarding Services

- **Prometheus:**

  ```sh
  kubectl port-forward svc/prometheus-operator-kube-p-prometheus -n monitoring 9090:9090 &
  ```

- **Grafana:**

  ```sh
  kubectl port-forward svc/prometheus-operator-grafana -n monitoring 3000:80 &
  ```

  - **Grafana Credentials:**
    - **User:** admin
    - **Password:** prom-operator

- **Access Dashboards:**

  - [Prometheus](http://localhost:9090)
  - [Grafana](http://localhost:3000)

---

## DNS Configuration

Edit the **/etc/hosts** file to enable accessing Nginx using a friendly domain:

```sh
127.0.0.1 nginx.elasticsearch.local
```

---

## Manual Installation Guide

### Install ArgoCD

```sh
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Retrieve ArgoCD Admin Password

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Port Forward and Login

```sh
kubectl port-forward -n argocd service/argocd-server 8443:443 &
argocd login localhost:8443
```

### Add Git Repository

```sh
argocd repo add https://github.com/AdamMilen/elasticsearch-assignment.git
```

### Install Nginx Ingress Controller

```sh
kubectl apply -f argocd/system-apps/ingress/ingress-nginx.yaml
```

### Install ECK Operator

```sh
kubectl create -f argocd/user-apps/es-operator/crds.yaml
kubectl create -f argocd/user-apps/es-operator/operator.yaml
kubectl apply -f argocd/user-apps/elasticsearch/elasticsearch.yaml
kubectl apply -f argocd/user-apps/elasticsearch/elasticsearch-ingress.yaml
```

### Change Elasticsearch Built-in User Password

```sh
kubectl exec -c elasticsearch -it elastic-linkerd-es-default-0 -n elastic-system -- elasticsearch-users passwd elastic -p adminadmin
```

### Port Forward Elasticsearch

```sh
kubectl port-forward service/quickstart-es-http 9200
```

---

## Install Prometheus Operator (Includes Grafana & AlertManager)

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kind-prometheus --namespace monitoring --create-namespace prometheus-community/kube-prometheus-stack -f argocd/system-apps-applications/values-prom-operator.yaml
```

### Install Prometheus Elasticsearch Exporter

```sh
helm install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter -f argocd/user-apps-applications/values-elasticsearch-exporter.yaml
```

### Configure ServiceMonitor for Prometheus Exporter

```sh
kubectl apply -f servicemonitor.yaml
```

---

## Install Linkerd

```sh
linkerd check --pre
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
```

### Port Forward Services

#### Grafana:

```sh
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kind-prometheus" -o name)
kubectl --namespace monitoring port-forward $POD_NAME 3000 &
```

#### Prometheus:

```sh
kubectl port-forward svc/prometheus-operator-kube-p-prometheus -n monitoring 9090:9090 &
```

---

### Setting Up Alerts to Slack

- [Guide to Kube-Prometheus Alert Integration](https://medium.com/@joudwawad/comprehensive-beginners-guide-to-kube-prometheus-in-kubernetes-monitoring-alerts-integration-4ade4fa8fa8c)
- **Slack Webhook URL:**
  ```sh
  https://hooks.slack.com/services/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
  ```

---

## Debugging Setup Issues

If the initial setup script fails, try running the script with different shells:

```sh
/usr/bin/bash
/bin/bash
```

---

This README provides a structured and easy-to-follow guide for setting up Elasticsearch, monitoring, and alerting within a Kubernetes environment using Nix, Kind, and ArgoCD.
