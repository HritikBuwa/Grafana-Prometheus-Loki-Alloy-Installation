#!/bin/bash
# =============================================================================
# setup.sh — Main installer for the Kubernetes Monitoring Stack
#
# What this script does:
#   1. Creates the "monitoring" namespace in your cluster
#   2. Installs Prometheus + Grafana (kube-prometheus-stack)
#   3. Waits for Prometheus to be fully ready
#   4. Installs Loki (log storage) + Alloy (log collector)
#   5. Tells you how to access everything
#
# Usage:
#   ./setup.sh
# =============================================================================

set -e  # Stop immediately if any command fails

# ── Colors for output ─────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log()  { echo -e "${BLUE}🔹 $1${NC}"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
echo ""
echo "=============================================="
echo "  Kubernetes Monitoring Stack — Setup"
echo "=============================================="
echo ""

# Check kubectl is available
if ! command -v kubectl &>/dev/null; then
  fail "kubectl not found. Please install kubectl first."
fi

# Check helm is available
if ! command -v helm &>/dev/null; then
  fail "helm not found. Please install Helm 3 first.
  Run: curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
       chmod 700 get_helm.sh && ./get_helm.sh"
fi

# Check cluster is reachable
if ! kubectl cluster-info &>/dev/null; then
  fail "Cannot connect to Kubernetes cluster.
  Make sure your cluster is running:
    kind:      kind create cluster
    minikube:  minikube start
    EKS:       aws eks update-kubeconfig --name YOUR_CLUSTER --region YOUR_REGION"
fi

ok "Pre-flight checks passed"
echo ""

# ── Step 1: Create namespace ──────────────────────────────────────────────────
log "Step 1/4 — Creating monitoring namespace..."
kubectl apply -f 01-namespace/namespace.yaml
ok "Namespace ready"
echo ""

# ── Step 2: Install Prometheus + Grafana ─────────────────────────────────────
log "Step 2/4 — Installing Prometheus + Grafana..."
bash 02-prometheus-grafana/install.sh
echo ""

# ── Wait for Prometheus stack to be ready ────────────────────────────────────
log "Waiting for Prometheus stack pods to be ready (this takes 1-3 minutes)..."
echo "   (watching for pods with label: release=monitoring-stack)"

# Wait for the main prometheus pod
kubectl wait --for=condition=ready pod \
  -l "app.kubernetes.io/name=grafana" \
  -n monitoring \
  --timeout=180s || warn "Grafana pod not ready yet — continuing anyway. Check with: kubectl get pods -n monitoring"

ok "Prometheus stack is up"
echo ""

# ── Step 3: Install Loki + Alloy ─────────────────────────────────────────────
log "Step 3/4 — Installing Loki + Alloy..."
bash 03-loki-alloy/install.sh
echo ""

# ── Step 4: Done ─────────────────────────────────────────────────────────────
ok "Step 4/4 — Setup Complete!"
echo ""
echo "=============================================="
echo "  🎉 Everything is installed!"
echo "=============================================="
echo ""
echo "  Next step — start the port-forwards:"
echo ""
echo "    ./04-access/access.sh"
echo ""
echo "  Then open Grafana:"
echo "    URL:      http://localhost:3000"
echo "    Username: admin"
echo "    Password: prom-operator"
echo ""
echo "  To verify everything is working:"
echo "    kubectl get pods -n monitoring"
echo ""
echo "  To read the full docs:"
echo "    cat docs/verify.md"
echo "    cat docs/troubleshooting.md"
echo "=============================================="
