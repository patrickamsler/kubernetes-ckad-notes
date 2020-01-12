# Exam Tips

## Set-up auto complete
https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-autocomplete
```bash
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

## Switch to root in the beginning
```bash
sudo -i
```

## Explain YAML format
```bash
kubectl explain pod --recursive | less
kubectl explain service | less
```

## Create YAML files with kubectl
```bash
#create a deployment yaml
kubectl run nginx --image=nginx --dry-run -o yaml > nginx.yaml

# --restart=Never creates a pod
kubectl run nginx --image=nginx --restart=Never --dry-run -o yaml > nginx.yaml

# create a job
kubectl run nginx --image=nginx --restart=OnFailure --dry-run -o yaml > nginx.yaml

# create a cronjob
kubectl run nginx --image=nginx --restart=OnFailure --schedule="* * * * *" --dry-run -o yaml > nginx.yaml
```

## Set default namespace
```shell script
kubectl config set-context --current --namespace=k8s-challenge-2-b
kubectl config set-context --current --namespace=default
```
