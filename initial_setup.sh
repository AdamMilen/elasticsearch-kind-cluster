#! /bin/bash

# deploying argocd

kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "waiting for argocd pods to be ready"
kubectl wait pods --all -n argocd --for condition=Ready --timeout=90s

# login in to argocd instance and adding repo
PASSWORD="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
kubectl port-forward -n argocd service/argocd-server 8443:443 &
echo "login into argocd and adding repo"
sleep 8
argocd login localhost:8443 --username admin --password "$PASSWORD" --insecure
argocd repo add https://github.com/AdamMilen/elasticsearch-assignment.git 

# Installing linkerd
linkerd check --pre
read -p "Do you want to continue and install linkerd? y/n " answer
if [ "$answer" == "y" ]; then
	linkerd install --crds | kubectl apply -f -
	linkerd install | kubectl apply -f -
	echo "waiting for linkerd control plane to be ready"
	kubectl wait pods --all -n linkerd --for condition=Ready --timeout=120s
	linkerd viz install | kubectl apply -f - # install the on-cluster metrics stack
	echo "waiting for linkerd extension to be ready"
	kubectl wait pods --all -n linkerd-viz --for condition=Ready --timeout=120s
	linkerd check
	linkerd viz dashboard &
	echo -e "Script finished\nYour username and password for argocd ui:\nadmin\n${PASSWORD}"
else
	exit
fi