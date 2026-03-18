#!/bin/bash
# =============================================================================
# 04-access/access.sh — Opens all monitoring services via port-forward
#
# What is port-forwarding?
#   Your monitoring services run INSIDE Kubernetes and are not directly
#   reachable from your laptop browser. Port-forwarding creates a tunnel:
#
#     Your laptop:3000  ──tunnel──►  Grafana pod:80      (inside cluster)
#     Your laptop:9090  ──tunnel──►  Prometheus pod:9090 (inside cluster)
#     Your laptop:9093  ──tunnel──►  Alertmanager:9093   (inside cluster)
#     Your laptop:3100  ──tunnel──►  Loki pod:3100       (inside cluster)
#
# Usage:
#   ./04-access/access.sh
#
# To stop:
#   Press Ctrl+C  (or run: pkill -f "kubectl port-forward")
#
# Note for EKS users:
#   If you set service type to LoadBalancer in install.sh, you don't
#   need this script. Run: kubectl get svc -n monitoring
#   and use the EXTERNAL-IP column directly in your browser.
# =============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
log()  { echo -e "${BLUE}🔹 $1${NC}"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo ""
echo "=============================================="
echo "  Starting port-forwards for all services"
echo "=============================================="
echo ""

# ── Kill any existing port-forwards first ─────────────────────────────────────
# This prevents "address already in use" errors if you run this script twice
log "Clearing any existing port-forwards..."
pkill -f 'kubectl port-forward' 2>/dev/null || true
sleep 1  # Brief pause to let ports be released
ok "Old port-forwards cleared"
echo ""

# ── Grafana ───────────────────────────────────────────────────────────────────
log "Starting Grafana port-forward (localhost:3000 → pod:80)..."
kubectl port-forward svc/monitoring-stack-grafana \
  -n monitoring 3000:80 --address=0.0.0.0 &
# The & runs it in the background so we can start the next one

# ── Prometheus ────────────────────────────────────────────────────────────────
log "Starting Prometheus port-forward (localhost:9090 → pod:9090)..."
kubectl port-forward svc/monitoring-stack-kube-prome-prometheus \
  -n monitoring 9090:9090 --address=0.0.0.0 &

# ── Alertmanager ──────────────────────────────────────────────────────────────
log "Starting Alertmanager port-forward (localhost:9093 → pod:9093)..."
kubectl port-forward svc/monitoring-stack-kube-prome-alertmanager \
  -n monitoring 9093:9093 --address=0.0.0.0 &

# ── Loki ──────────────────────────────────────────────────────────────────────
log "Starting Loki port-forward (localhost:3100 → pod:3100)..."
kubectl port-forward svc/loki \
  -n monitoring 3100:3100 --address=0.0.0.0 &

# Brief wait for tunnels to establish
sleep 2

echo ""
echo "=============================================="
ok "All services are accessible!"
echo "=============================================="
echo ""
echo "  Service       URL                     Login"
echo "  ─────────     ──────────────────────  ───────────────────"
echo "  Grafana     → http://localhost:3000   admin / prom-operator"
echo "  Prometheus  → http://localhost:9090   (no login)"
echo "  Alertmanager→ http://localhost:9093   (no login)"
echo "  Loki API    → http://localhost:3100   (no login)"
echo ""
echo "  Press Ctrl+C to stop all port-forwards"
echo "  Or run: pkill -f 'kubectl port-forward'"
echo "=============================================="
echo ""

# "wait" keeps the script alive so all the background port-forwards
# stay running. Without this, the script exits and they all die.
wait
