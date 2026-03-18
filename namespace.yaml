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
