#! /usr/bin/bash

# deploying argocd
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait pods --all -n argocd --for condition=Ready --timeout=90s

# login in to argocd instance and adding repo
PASSWORD="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
kubectl port-forward -n argocd service/argocd-server 8443:443 &
argocd login localhost:8443 --username admin --password "$PASSWORD"
argocd repo add https://github.com/AdamMilen/elasticsearch-assignment.git --username AdamMilen --password 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
