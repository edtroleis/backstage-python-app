#!/bin/sh

printf "\n# Checking if kind is installed... if not, it will be installed.\n"
if command -v kind &> /dev/null; then
  echo "Kind is installed:"
  kind version
else
  # For AMD64 / x86_64
  [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
  # For ARM64
  [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-arm64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
fi

printf "\n# Checking if there is a kind cluster... if not, it will be created.\n"

if kind get clusters | grep -q "^kind$"; then
  printf "Kind cluster already exists."; echo
  exit 1
else
  printf "\n# Create a Kind cluster with extra port mappings for HTTP and HTTPS\n"
  cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

  printf "\n# Setup ingress NGINX\n"
  kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml

  sleep 60

  printf "\n# Add argo helm repo and install ArgoCD\n"
  
  # Add error handling for helm repo
  if ! helm repo add argo https://argoproj.github.io/argo-helm; then
    printf "❌ Failed to add Argo helm repository. Trying alternative method...\n"
    # Try updating existing repos first
    helm repo update
    # If still fails, use direct manifest installation
    if ! helm repo add argo https://argoproj.github.io/argo-helm; then
      printf "Using direct manifest installation instead of Helm...\n"
      kubectl create namespace argocd
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      printf "✅ ArgoCD installed via direct manifest\n"
    fi
  else

    helm repo update argo
    kubectl create namespace argocd
    
    # Try helm installation with retry logic
    max_retries=3
    retry_count=0
    helm_success=false
    
    while [ $retry_count -lt $max_retries ]; do
      printf "Attempting to install ArgoCD via Helm (attempt $((retry_count + 1))/$max_retries)...\n"
      
      if helm upgrade --install argocd argo/argo-cd -n argocd -f ../charts/argocd/values-argo.yaml --timeout=10m --wait; then
        printf "✅ ArgoCD installed successfully via Helm\n"
        helm_success=true
        break
      else
        retry_count=$((retry_count + 1))
        if [ $retry_count -eq $max_retries ]; then
          printf "❌ Helm installation failed after $max_retries attempts. Using direct manifest installation...\n"
          kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
          printf "✅ ArgoCD installed via direct manifest as fallback\n"
        else
          printf "Helm installation failed. Retrying in 30 seconds...\n"
          sleep 30
        fi
      fi
    done
  fi
fi
