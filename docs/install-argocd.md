# Deploy ArgoCD
- https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd

```bash
# "argo" has been added to your repositories
helm repo add argo https://argoproj.github.io/argo-helm

# list helm repositories
helm repo ls

# install the Argo CD chart
cd charts/argo-cd
kubectl create namespace argocd
helm upgrade --install argocd argo/argo-cd -n argocd -f values-argo.yaml --timeout=5m --wait


helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace -f values-argo.yaml

kubectl get ns
kubectl get pods -n argocd
kubectl get ing -n argocd
```


127.0.0.1 argocd.test.com




## If you don't want to use ingress, you can access the ArgoCD UI via port-forward
kubectl port-forward service/argocd-server -n argocd 8080:443

# open the browser and accept the certificate
http://localhost:8080


# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Notes
[Getting Started Guide] (https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)




https://python-app.test.com/api/v1/info
http://localhost:5000/api/v1/info
https://argocd.test.com/
