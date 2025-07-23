# Deploy Python app

## Add hostname entry to Windows hosts file -  C:\Windows\System32\drivers\etc\hosts

```bash
127.0.0.1    python-app.test.com
```

## Remove previous deployment, service, and ingress objects

```bash
kubectl delete -f ./k8s/deployment.yaml
kubectl delete -f ./k8s/service.yaml
kubectl delete -f ./k8s/ingress.yaml
```

## Uninstall previous Helm release

```bash
helm uninstall python-app -n python
```

## Create Kubernetes resources

It's necessary create/deploy
1. deployment: `kubectl apply -f ./k8s/deployment.yaml`
2. service: `kubectl apply -f ./k8s/service.yaml`
3. ingress: `kubectl apply -f ./k8s/ingress.yaml`

## Check the connectivity

```bash
# Check on the browser
http://localhost/api/v1/info
http://localhost/api/v1/healthz
```
