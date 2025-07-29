# Kind

## Install Kind
```bash
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Create a Kind cluster with extra port mappings for HTTP and HTTPS
```bash
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
```

### Verify the cluster
```bash
kind get clusters
kubectl cluster-info
kubectl get nodes
```

### Setup ingress NGINX
```bash
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
```

### Test Ingress NGINX
```bash
# Check on the browser
http://localhost
https://localhost
```

# Deploy the Python app

## Create the Kubernetes resources

It's necessary create/deploy
1. deployment: `kubectl apply -f ./k8s/deployment.yaml`
2. service: `kubectl apply -f ./k8s/service.yaml`
3. ingress: `kubectl apply -f ./k8s/ingress.yaml`

## Add hostname entry to Windows hosts file -  C:\Windows\System32\drivers\etc\hosts
```bash
127.0.0.1    python-app.test.com
```

## Check the connectivity

```bash
# Check on the browser
http://localhost/api/v1/info
http://localhost/api/v1/healthz
```


