# 🚀 Kubernetes Monitoring Stack

A **complete, beginner-friendly** observability stack for Kubernetes.
One command sets up everything — metrics, logs, and dashboards.

```
Prometheus  →  collects metrics from your cluster
Grafana     →  shows dashboards and graphs
Loki        →  stores logs from all your pods
Alloy       →  collects pod logs and sends them to Loki
```

> ✅ Works on **kind** · **minikube** · **EKS**
> ✅ Uses only **current, non-deprecated** tools (2026)

---

## 📁 Project Structure

```
monitoring-stack/
├── README.md                        ← you are here
├── setup.sh                         ← run this to install everything
├── cleanup.sh                       ← run this to remove everything
│
├── 01-namespace/
│   └── namespace.yaml               ← creates the "monitoring" namespace
│
├── 02-prometheus-grafana/
│   └── install.sh                   ← installs Prometheus + Grafana
│
├── 03-loki-alloy/
│   ├── install.sh                   ← installs Loki + Alloy
│   └── alloy-values.yaml            ← Alloy log collection config
│
├── 04-access/
│   └── access.sh                    ← opens all services in your browser
│
└── docs/
    ├── platform-notes.md            ← kind vs minikube vs EKS differences
    ├── verify.md                    ← how to confirm everything works
    └── troubleshooting.md           ← common problems and fixes
```

---

## 🛠️ Prerequisites — Install Required Tools

Before anything else, make sure these tools are on your machine.

### 1. Install kubectl
kubectl is the command-line tool to talk to your Kubernetes cluster.

```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# macOS (with Homebrew)
brew install kubectl

# Verify
kubectl version --client
```

### 2. Install Helm
Helm is the package manager for Kubernetes (like apt/brew but for K8s apps).

```bash
# Linux / macOS / WSL
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Verify
helm version
```

### 3. Install Docker
Docker is required by both kind and minikube to run the cluster locally.

```bash
# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y docker.io
sudo usermod -aG docker $USER   # lets you run docker without sudo
newgrp docker                   # apply group change without logout

# macOS
# Download Docker Desktop from https://www.docker.com/products/docker-desktop

# Verify
docker --version
```

---

## ☸️ Step 0 — Create Your Kubernetes Cluster

Pick the platform you want to use and follow that section.
**Skip this if you already have a running cluster.**

---

### Option A — kind (recommended for local dev)

kind runs Kubernetes inside Docker containers. Fastest to set up.

```bash
# Install kind
# Linux / WSL
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# macOS
brew install kind

# Verify
kind version
```

```bash
# Create a cluster
kind create cluster --name monitoring-demo

# Check it's running
kubectl cluster-info --context kind-monitoring-demo
kubectl get nodes
# Expected: one node showing Ready
```

```bash
# When you're done (optional — deletes the whole cluster)
kind delete cluster --name monitoring-demo
```

> ⚠️ **kind limitation:** Services are NOT reachable via browser directly.
> Always use `./04-access/access.sh` (port-forwarding) to open dashboards.

---

### Option B — minikube (good for local dev with more features)

minikube runs Kubernetes in a virtual machine or Docker on your laptop.

```bash
# Install minikube
# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# macOS
brew install minikube

# Verify
minikube version
```

```bash
# Start a cluster (give it enough resources for the monitoring stack)
minikube start --cpus=4 --memory=8192 --driver=docker

# Check it's running
kubectl get nodes
# Expected: minikube node showing Ready
```

```bash
# Useful minikube commands
minikube status          # check if cluster is running
minikube stop            # pause the cluster (keeps your data)
minikube delete          # delete everything and start fresh
minikube dashboard       # open Kubernetes dashboard in browser
```

> 💡 **minikube tip:** You can use `minikube service <service-name> -n monitoring`
> instead of port-forwarding to open dashboards directly in your browser.

---

### Option C — EKS (Amazon Elastic Kubernetes Service)

EKS is a managed Kubernetes cluster on AWS. Use this for staging/production.

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (e.g. us-east-1), output format: json

# Install eksctl (the easiest way to create EKS clusters)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify
aws --version
eksctl version
```

```bash
# Create an EKS cluster (takes ~15 minutes)
eksctl create cluster \
  --name monitoring-demo \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed

# This automatically updates your kubeconfig
# Verify
kubectl get nodes
# Expected: 2 nodes showing Ready
```

```bash
# Delete the cluster when done (stops AWS charges)
eksctl delete cluster --name monitoring-demo --region us-east-1
```

> ⚠️ **EKS costs money.** A 2-node `t3.medium` cluster costs roughly $0.10/hour.
> Always delete when you're done to avoid unexpected charges.

> 💡 **EKS tip:** Change `ClusterIP` to `LoadBalancer` in `02-prometheus-grafana/install.sh`
> so services get public AWS URLs automatically — no port-forwarding needed.

---

## ⚡ Quick Start (3 steps)

### Step 1 — Clone this repo
```bash
git clone https://github.com/YOUR_USERNAME/monitoring-stack.git
cd monitoring-stack
```

### Step 2 — Make scripts executable
```bash
chmod +x *.sh */*.sh
```

### Step 3 — Run setup
```bash
./setup.sh
```

That's it. The script will install everything and tell you when it's done.

---

## 🌐 Access the dashboards

After setup completes, run:
```bash
./04-access/access.sh
```

Then open your browser:

| Service      | URL                     | Login                  |
|--------------|-------------------------|------------------------|
| **Grafana**  | http://localhost:3000   | admin / prom-operator  |
| **Prometheus** | http://localhost:9090 | no login               |
| **Alertmanager** | http://localhost:9093 | no login             |
| **Loki API** | http://localhost:3100   | no login               |

---

## 📊 Add Loki as a Data Source in Grafana

After opening Grafana:

1. Go to **Connections → Data Sources → Add new data source**
2. Choose **Loki**
3. Set URL to exactly: `http://loki.monitoring.svc.cluster.local:3100`
4. Click **Save & Test** — you should see a green ✅

> ⚠️ Do NOT use `http://loki:3100` — it will fail. Always use the full service URL above.

---

## 🔍 Explore Logs in Grafana

1. Go to **Explore** (compass icon in left sidebar)
2. Select **Loki** as the data source
3. Try these queries:

```logql
# All logs from the monitoring namespace
{namespace="monitoring"}

# Logs from a specific pod
{pod=~"loki.*"}

# Filter logs that contain the word "error"
{namespace="monitoring"} |= "error"
```

---

## 🧹 Cleanup

To remove everything:
```bash
./cleanup.sh
```

---

## 📚 More Docs

- [Platform Notes](docs/platform-notes.md) — kind vs minikube vs EKS differences
- [Verify Everything Works](docs/verify.md) — step-by-step checks
- [Troubleshooting](docs/troubleshooting.md) — common problems and fixes

---

## 🧱 Stack Components

| Component | What it does | Helm Chart | Status |
|-----------|-------------|------------|--------|
| Prometheus | Scrapes and stores metrics | kube-prometheus-stack | ✅ Active |
| Grafana | Dashboards and alerts UI | kube-prometheus-stack | ✅ Active |
| Alertmanager | Routes and sends alerts | kube-prometheus-stack | ✅ Active |
| Loki | Stores and indexes logs | grafana/loki v3 | ✅ Active |
| Grafana Alloy | Collects logs from pods | grafana/alloy | ✅ Active |
| ~~Promtail~~ | ~~Old log collector~~ | ~~grafana/promtail~~ | ❌ Deprecated Feb 2026 |
| ~~loki-stack~~ | ~~Old bundled chart~~ | ~~grafana/loki-stack~~ | ❌ Deprecated |
