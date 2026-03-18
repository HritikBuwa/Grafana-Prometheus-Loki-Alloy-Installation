# 🖥️ Platform-Specific Notes

This stack works on kind, minikube, and EKS — but each platform has small differences.

---

## kind (Kubernetes in Docker)

kind runs your entire Kubernetes cluster inside Docker containers on your laptop.

### Setup
```bash
# Create a kind cluster (if you haven't already)
kind create cluster --name my-cluster

# Verify it's running
kubectl cluster-info --context kind-my-cluster
```

### ⚠️ Important: NodePort does NOT work on kind

On a normal cluster, NodePort services are reachable directly via `localhost:PORT`.
On kind, they are NOT — because the cluster nodes are Docker containers with their
own network, and ports are not exposed to your laptop automatically.

**The fix:** always use port-forwarding to access services.
That's exactly what `./04-access/access.sh` does for you.

### If you want NodePort to work on kind (optional advanced setup)

Create a kind config file with port mappings BEFORE creating the cluster:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30000
        hostPort: 30000    # Prometheus
      - containerPort: 31000
        hostPort: 31000    # Grafana
      - containerPort: 32000
        hostPort: 32000    # Alertmanager
```

```bash
kind create cluster --name my-cluster --config kind-config.yaml
```

Then you can access services directly without port-forwarding.

---

## minikube

minikube runs Kubernetes in a virtual machine or Docker on your laptop.

### Setup
```bash
# Start minikube with enough resources
minikube start --cpus=4 --memory=8192

# Verify
kubectl cluster-info
```

### Option 1: Use port-forward (same as kind)
```bash
./04-access/access.sh
```

### Option 2: Use minikube service (easier — opens browser automatically)
```bash
# Opens Grafana in your default browser
minikube service monitoring-stack-grafana -n monitoring

# Opens Prometheus
minikube service monitoring-stack-kube-prome-prometheus -n monitoring
```

### Option 3: Use minikube tunnel (for LoadBalancer services)
```bash
# Run this in a separate terminal — it stays running
minikube tunnel

# Then get the external IP
kubectl get svc -n monitoring
```

---

## EKS (Amazon Elastic Kubernetes Service)

EKS is a managed Kubernetes service on AWS. It has real cloud IPs so
you don't need port-forwarding.

### Setup
```bash
# Connect kubectl to your EKS cluster
aws eks update-kubeconfig --region us-east-1 --name YOUR_CLUSTER_NAME

# Verify
kubectl get nodes
```

### Change service type to LoadBalancer

In `02-prometheus-grafana/install.sh`, change all three `ClusterIP` lines to `LoadBalancer`:

```bash
# Find this in install.sh:
--set prometheus.service.type=ClusterIP \
--set grafana.service.type=ClusterIP \
--set alertmanager.service.type=ClusterIP

# Change to:
--set prometheus.service.type=LoadBalancer \
--set grafana.service.type=LoadBalancer \
--set alertmanager.service.type=LoadBalancer
```

After installing, get your public URLs:
```bash
kubectl get svc -n monitoring
# Look at the EXTERNAL-IP column — that's your public URL
```

### Use S3 for Loki storage on EKS (for production)

The default filesystem storage loses logs if the Loki pod restarts.
For EKS production use, switch to S3:

```bash
# Create an S3 bucket first
aws s3 mb s3://my-loki-logs --region us-east-1

# Then in 03-loki-alloy/install.sh, change the helm install flags to:
helm install loki grafana/loki \
  --namespace monitoring \
  --set loki.commonConfig.replication_factor=1 \
  --set loki.storage.type=s3 \
  --set loki.storage.s3.bucketnames=my-loki-logs \
  --set loki.storage.s3.region=us-east-1 \
  --set singleBinary.replicas=1 \
  --set minio.enabled=false \
  --set loki.auth_enabled=false
```

> Note: Your EKS node IAM role needs `s3:PutObject`, `s3:GetObject`, and `s3:ListBucket` permissions on the bucket.

---

## Quick Comparison

| Feature            | kind              | minikube          | EKS                     |
|--------------------|-------------------|-------------------|-------------------------|
| Where it runs      | Docker containers | VM or Docker      | AWS cloud               |
| Access method      | port-forward only | port-forward or `minikube service` | LoadBalancer (auto IP) |
| Loki storage       | filesystem (lost on restart) | filesystem | Use S3 (persistent) |
| Cost               | Free              | Free              | AWS charges apply       |
| Best for           | CI, quick local   | Local dev/testing | Staging / Production    |
| Multi-node support | ✅ Yes            | ⚠️ Limited        | ✅ Full                 |
