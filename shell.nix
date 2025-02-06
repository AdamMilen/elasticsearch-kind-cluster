{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  packages = with pkgs; [ 
    kubernetes-helm
    argocd
    git
    gh
    kind
    kubectl
  ];
}
