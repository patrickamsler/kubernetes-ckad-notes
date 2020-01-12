# Kubernetes

## API Primitives 
Get information about Kubernetes objects
```bash
kubectl get <object>
kubectl get pods 
kubectl get nodes 
```
* Spec defines the requested state of an object (yaml) 
* State: the actual state which not necessarily matches the spec 

* Print spec and status in yaml format: `kubectl get nodes $node_name -o yaml`
* Information about the object: `kubectl describe node $node_name`

## Pods 
Runs one or more container. Typically only a single container per pod. See multi container pods
Example yaml for a pod: 

```yaml
apiVersion: v1 
kind: Pod 
metadata: 
  name: my-pod 
  labels: 
    app: myapp 
spec: 
  containers: 
  - name: myapp-container 
    image: busybox 
    command: ['sh', '-c', 'echo Hello Kubernetes! && sleep 3600'] 
```
The yaml file creates a pod with a single container based on the busybox image. You can specify a command that overrides the default command of the container image. 

Create a pod from the yaml definition file: `kubectl create -f my-pod.yml`
 
Edit a pod by updating the yaml definiton and re-applying it: `kubectl apply -f my-pod.yml`
 
You can also edit a pod like this with the linux default editor: `kubectl edit pod my-pod`
 
You can delete a pod like this: `kubectl delete pod my-pod`

Connect to shell of running container: `kubectl exec -it my-pod -- /bin/sh`

Execute command in the container: `kubectl exec my-pod -- ls`

Get the container's logs: `kubectl logs counter`

For a multi-container pods you have to specify the container with the -c flag: `kubectl logs <pod name> -c <container name>`

It is possible to download the pod spec. Useful if edit doesn't work and the pod has to be recreated: `kubectl get pod nginx -n nginx-ns -o yaml --export > nginx-pod.yml`

## Namespaces 

Separates applications or teams within the same cluster. If you don't specify a namespace, the object gets created in the default namespace. 

You can get a list of the namespaces in the cluster like this: `kubectl get namespaces`

You can also create your own namespaces: `kubectl create ns my-ns`

If the namespace is not defined, only the pods in the default namespace are listed: `kubectl get pods -n my-ns` 

 
## Config Maps 

Config maps contain configurations that are common to all containers in the cluster. Config Maps contain key-value pairs that either can be access directly or can be mounted to the filesystem of the container. 

Create config map in the cluster: `kubectl create -f my-config-map-pod.yml`

Config map example: 
```yaml
apiVersion: v1 
kind: ConfigMap 
metadata: 
   name: my-config-map 
data: 
   myKey: myValue 
   anotherKey: anotherValue 
```

Access config map in container spec with environment variable: 
```yaml
spec: 
  containers: 
  - name: myapp-container 
    image: busybox 
    command: ['sh', '-c', "echo $(MY_VAR) && sleep 3600"] 
    env: 
    - name: MY_VAR 
      valueFrom: 
        configMapKeyRef: 
          name: my-config-map 
          key: myKey 
```
It is also possible to mount the config map to the file system of the container. Each key from the config map is a file: 
```yaml
spec: 
  containers: 
  - name: myapp-container 
    image: busybox 
    command: ['sh', '-c', "echo (cat /etc/config/myValue) && sleep 3600"] 
    volumeMounts: 
      - name: config-volume 
        mountPath: /etc/config 
  volumes: 
    - name: config-volume 
      configMap: 
        name: my-config-map 
```

## Security Context 
Commands/processes inside the container run as root user by default. If a mounted file from the node is accessed inside the container, the file is access with root user rights. If we want to run a container with the right of a specific user or group, we can specify this in the container spec. 

Access the file with the rights of the user identified by id 2001 
```yaml
spec: 
  securityContext: 
    runAsUser: 2001 
    fsGroup: 3001 
  containers: 
  - name: myapp-container 
    image: busybox 
    command: ['sh', '-c', "cat /message/message.txt && sleep 3600"] 
```

## Resources 
If a pod is created, the node scheduler selects the node based on the requested resources in the container spec. If the specified limits are reached, the pod will be evicted.

### CPU
Limits and requests for CPU resources are measured in cpu units. One cpu, in Kubernetes, is equivalent to:
* AWS vCPU
* GCP Core
* Hyperthread on a bare-metal Intel processor with Hyperthreading

0.5 means half a CPU. 0.1 is equivalent to the expression 100m. 

### Memory
Limits and requests for memory are measured in bytes. 128Mi means 128 mega byte memory.

Example

```yaml
spec:
  containers:
  - name: myapp-contaianer
    image: busybox
    command: ['sh', '-c', 'echo Hello Kubernetes! && sleep 3600']
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```
Resource usage can be checked with the top command
```bash
kubectl top pods
kubectl top pod my-pod
kubectl top pods -n my-namespace
kubectl top nodes
```

## Secrets 
Used to store sensitive information such as passwords and access tokens. The format is similar to config maps. 
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
stringData:
  myKey: myPassword
```
Access in container spec: 
```yaml
spec: 
  containers: 
  - name: myapp-container 
    image: busybox 
    command: ['sh', '-c', "echo Hello, Kubernetes! && sleep 3600"] 
    env: 
    - name: MY_PASSWORD 
      valueFrom: 
        secretKeyRef: 
          name: my-secret 
          key: myKey 
```

## Liveness and Readiness Probes
### Livness
Indicates whether the container is running. If the liveness probe fails, the kubelet kills the container, and the container is subjected to its restart policy.

Livness probe with command
```yaml
spec:
  containers:
  - name: myapp-container
    image: busybox
    command: ['sh', '-c', "echo Hello, Kubernetes! && sleep 3600"]
    livenessProbe:
      exec:
        command:
        - echo
        - testing
      initialDelaySeconds: 5
      periodSeconds: 5
```

### Readiness
Indicates whether the container is ready to service requests. If the readiness probe fails, the endpoints controller removes the Pod’s IP address from the endpoints of all services. 

Readiness HTTP probe
```yaml
spec:
  containers:
  - name: myapp-container
    image: nginx
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
```

## Labels and Annotations
Kubernetes labels provide a way to attach custom, identifying information to your objects. Selectors can then be used to filter objects using label data as criteria
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-development-label-pod
  labels:
    app: my-app
    environment: development
spec:
  containers:
  - name: nginx
    image: nginx
```
You can use selectors to query pods
```bash
kubectl get pods -l app=my-app
kubectl get pods -l environment=production
kubectl get pods -l environment=development
kubectl get pods -l environment!=production
kubectl get pods -l 'environment in (development,production)'
kubectl get pods -l app=my-app,environment=production
```

## Deployments
Deployments can be used to manage a group of replica sets (pods).
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```
* spec.replica: the number of pods that are going to be created
* spec.template: describes the pods that will be created
* spec.selector: selects the templates that are managed by this deployment

For each replica a pod with its own ip address gets created. That's how it is possible to expose same container port multiple time.
```bash
# show pods ip 
kubectl get pods -l app=nginx -o yaml | grep podIP

# access port 80 on specific pod (ssh into node in cluster)
curl 10.40.0.7:80
```

You can mange deployments like any other object in Kubernetes
```bash
kubectl get deployments
kubectl get deployment <deployment_name>
kubectl describe deployment <deployment_name>
kubectl edit deployment <deployment_name>
kubectl delete deployment <deployment_name>
```

### Rolling deployment
1. create the deployment: `kubectl apply -f rolling-deployment.yml`
2. change the image of a deployment: `kubectl set image deployment/rolling-deployment nginx=nginx:1.7.9 --record`
3. check the status of the update: `kubectl rollout status deployment/rolling-deployment`
3. show the history of the deployment: `kubectl rollout history deployment/rolling-deployment`
4. show details about a specif version: `kubectl rollout history deployment/rolling-deployment --revision=2`
5. rollback to a previous version: `kubectl rollout undo deployment/rolling-deployment`

You can define the strategy for the rolling deployment in the deployment spec
```yaml
spec:
  strategy:
    rollingUpdate:
      maxSurge: 3
      maxUnavailable: 2
```
* spec.strategy.rollingUpdate.maxUnavailable: maximum number of pods that can be unavailable during update
* .spec.strategy.rollingUpdate.maxSurge: max number of additional pods that can be created during the update

## Service
Services provide a way to access dynamically create pods. 
If a deployment creates multiple containers with the same port, a service routs the network traffic from a single port to the dynamically created pods.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
```

* spec.type ClusterIP: routes the traffic inside the cluster to the target ports of the pods. ClusterIP can only be access inside the cluster.
* spec.ports.port: the port where the service listening on
* spec.ports.targetPort: the ports exposed by the container

`curl <service-ip>:8080` equal to `curl <pod-ip>:80`

If the selector of the service selects multiple pods, ClusterIP uses round robin/random to forward the traffic.

```bash
# show all services
kubectl get service

# show the endpoints of the service
kubectl get endpoints my-servic
``` 

### Service type
* ClusterIP: only reachable within the cluster.
* NodePort: exposes the port on each nodes ip. 
  `nginx-svc    NodePort    10.43.240.110   <none>        3000:30743/TCP   3s    app=nginx`
  Within the cluster the NodePort service can be reached at 3000. If accessed trough the node itself at port 30743 (e.g. ssh to vm and then localhost:30743)


## Jobs and Cronjobs
* Jobs provide a way in Kubernetes to start a pod once and run it until completion
* Cronjobs are similar to unix cron jobs. They start a pod in a specific interval

```bash
kubectl get jobs
kubectl get cronjobs
```

## Network Policy
By default, pods are not isolated and accept traffic from any source. Network policies provide a way to restrict traffic to certain pods.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-network-policy
spec:
  podSelector:
    matchLabels:
      app: secure-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          allow-access: "true"
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          allow-access: "true"
    ports:
    - protocol: TCP
      port: 80
```

* Ingress: Accept only incoming traffic from pods with the 'allow-access' label on port 80
* Egress: Allow only outgoing traffic to pods with the 'allow-access' label on port 80

## Volumes
Volumes can be mounted to containers, for instance if two containers want to share data.
If a container is restarted, the volume persists.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-pod
spec:
  containers:
  - image: busybox
    name: busybox
    command: ["/bin/sh", "-c", "while true; do mkdir /tmp/storage; echo 'hello world' > /tmp/storage/hello.txt; sleep 3600; done"]
    volumeMounts:
    - mountPath: /tmp/storage
      name: my-volume
  volumes:
  - name: my-volume
    emptyDir: {}
```
The empty dir volume is created on the node if the pod gets assigned to it the first time. If the pod is removed, the directory gets also removed.

* spec.volumes: defines a empty directory outside the container
* spec.containers.volumeMounts: defines which directory inside the container is mounted externally

### Persistent Volume
Persistent volumes are not associated with a specific pod. They are usually created by the admin and back by physical storage provided by the cloud service.
```yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: my-pv
spec:
  storageClassName: local-storage
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
```
The storageClassName can be any string

Pods can access PersistentVolumes through Claims. The claim request a specifc storage class and size.
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: local-storage
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 512Mi
```

A Pod uses the PersistentVolumeClaim to mount storage
```yaml
kind: Pod
apiVersion: v1
metadata:
  name: my-pvc-pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["/bin/sh", "-c", "while true; do sleep 3600; done"]
    volumeMounts:
    - mountPath: "/mnt/storage"
      name: my-storage
  volumes:
  - name: my-storage
    persistentVolumeClaim:
      claimName: my-pvc
```
