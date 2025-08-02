https://github.com/actions/actions-runner-controller/blob/master/docs/quickstart.md


## 1. Install cert-manager in your cluster

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml

kubectl get ns
kubectl get pods -n cert-manager
```

## 2. Next, Generate a Personal Access Token (PAT) for ARC to authenticate with GitHub.

Login to your GitHub account and Navigate to [Create new Token](https://github.com/settings/tokens/new).
Select repo.
Click Generate Token and then copy the token locally ( we’ll need it later).

## Deploy and configure ARC on your K8s cluster

### Helm deployment
Add repository

```bash
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
```

Install Helm chart
```bash
helm upgrade --install --namespace actions-runner-system --create-namespace\
  --set=authSecret.create=true\
  --set=authSecret.github_token=$GITHUB_RUNNERS_TOKEN\
  --wait actions-runner-controller actions-runner-controller/actions-runner-controller
```
*note:- Replace REPLACE_YOUR_TOKEN_HERE with your PAT that was generated previously.

### 3. Create the GitHub self hosted runners and configure to run against your repository
```yaml
cat << EOF | kubectl apply -n actions-runner-system -f -
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: self-hosted-runner
spec:
  replicas: 1
  template:
    spec:
      repository: edtroleis/backstage-python-app
EOF
```

kubectl get pods -n actions-runner-system
