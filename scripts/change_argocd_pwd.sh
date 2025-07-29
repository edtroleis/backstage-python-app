change_argocd_pwd() {
  ARGOCD_USER="admin"
  ARGOCD_NEW_PWD="edtroleis"
  ARGOCD_URL=argocd.test.com

  max_login_attempts=5
  login_attempt=0

  printf "\n# Setting ArgoCD admin password\n"
  ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

  # Wait for ArgoCD server to be ready before attempting login
  printf "Waiting for ArgoCD server to be ready...\n"
  kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

  # Check if argocd CLI is available, if not install it
  if ! command -v argocd &> /dev/null; then
    printf "Installing ArgoCD CLI...\n"
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
  fi

  # Login to ArgoCD CLI and change password  
  while [ $login_attempt -lt $max_login_attempts ]; do
    printf "Attempting to login to ArgoCD (attempt $((login_attempt + 1))/$max_login_attempts)...\n"
    
    if argocd login $ARGOCD_URL --username $ARGOCD_USER --password $ARGOCD_PWD --insecure --grpc-web; then
      printf "✅ Successfully logged in to ArgoCD\n"
      
      # Change the admin password
      if argocd account update-password --account $ARGOCD_USER --current-password $ARGOCD_PWD --new-password $ARGOCD_NEW_PWD --grpc-web; then
        printf "✅ Password changed successfully!\n"
        ARGOCD_PWD=$ARGOCD_NEW_PWD
      else
        printf "⚠️ Failed to change password, keeping original password\n"
      fi
      break
    else
      login_attempt=$((login_attempt + 1))
      if [ $login_attempt -eq $max_login_attempts ]; then
        printf "❌ Failed to login to ArgoCD after $max_login_attempts attempts\n"
        printf "You can manually change the password later using:\n"
        printf "argocd login $ARGOCD_URL --username admin --password $ARGOCD_PWD --insecure\n"
        printf "argocd account update-password --account admin --current-password $ARGOCD_PWD --new-password $ARGOCD_NEW_PWD\n"
      else
        printf "Login failed. Retrying in 15 seconds...\n"
        sleep 15
      fi
    fi
  done

  printf "\n# ArgoCD setup complete. You can access the UI at https://$ARGOCD_URL\n"
  printf "Username: $ARGOCD_USER\n"
  printf "Password: $ARGOCD_PWD\n"
}
