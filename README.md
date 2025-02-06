# elasticsearch-assignment

copy shell.nix to your working directory
run nix-shell
run kind create cluster --name=multi-node-cluster --config=kind-config

# check if kind cluster created
kubectl get no

# install argocd
kubectl create ns argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml