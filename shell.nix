{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  packages = with pkgs; [
    linkerd_edge
    yq 
    kubernetes-helm
    argocd
    git
    gh
    kind
    kubectl
  ];
}
