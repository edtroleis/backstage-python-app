# Deploy Python app with Helm

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

```bash
helm install python-app -n python ./charts/python-app --create-namespace
```

## Check the connectivity

```bash
# Check on the browser
http://localhost/api/v1/info
http://localhost/api/v1/healthz
```
