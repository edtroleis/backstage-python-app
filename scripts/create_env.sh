#!/bin/bash

printf "\n# Creating a Kind cluster...\n"
source ./install_configure_kind.sh
install_configure_kind

printf "\n# Testing ArgoCD accessibility...\n"
source ./check_argocd_health.sh
check_argocd_health

printf "\n# Changing ArgoCD admin password...\n"
source ./change_argocd_pwd.sh
change_argocd_pwd
