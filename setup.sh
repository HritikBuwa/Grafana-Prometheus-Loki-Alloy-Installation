#!/bin/bash
# =============================================================================
# cleanup.sh — Removes everything installed by setup.sh
#
# What this script does:
#   1. Stops all running port-forwards
#   2. Uninstalls Alloy (log collector)
#   3. Uninstalls Loki (log storage)
#   4. Uninstalls Prometheus + Grafana stack
#   5. Deletes the monitoring namespace
#
# Usage:
#   ./cleanup.sh
#
# Note: Each step uses "|| true" so the script doesn't stop if a
#       component was never installed (safe to run on a fresh cluster).
# =============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}🔹 $1${NC}"; }
ok()  { echo -e "${GREEN}✅ $1${NC}"; }

echo ""
echo "=============================================="
echo "  Kubernetes Monitoring Stack — Cleanup"
echo "=============================================="
echo ""

# ── Stop port-forwards ────────────────────────────────────────────────────────
log "Stopping any running port-forwards..."
# The "|| true" means: if no port-forwards are running, don't fail — just continue
pkill -f 'kubectl port-forward' 2>/dev/null || true
ok "Port-forwards stopped"
echo ""

# ── Uninstall Alloy ───────────────────────────────────────────────────────────
log "Removing Alloy (log collector)..."
# "|| echo" means: if not installed, print a message and keep going
helm uninstall alloy -n monitoring 2>/dev/null || echo "   (alloy was not installed — skipping)"
ok "Alloy removed"
echo ""

# ── Uninstall Loki ────────────────────────────────────────────────────────────
log "Removing Loki (log storage)..."
helm uninstall loki -n monitoring 2>/dev/null || echo "   (loki was not installed — skipping)"
ok "Loki removed"
echo ""

# ── Uninstall Prometheus + Grafana ────────────────────────────────────────────
log "Removing Prometheus + Grafana stack..."
helm uninstall monitoring-stack -n monitoring 2>/dev/null || echo "   (monitoring-stack was not installed — skipping)"
ok "Prometheus + Grafana removed"
echo ""

# ── Delete namespace ──────────────────────────────────────────────────────────
log "Deleting monitoring namespace..."
kubectl delete namespace monitoring 2>/dev/null || echo "   (namespace did not exist — skipping)"
ok "Namespace deleted"
echo ""

echo "=============================================="
echo "  🧹 Cleanup complete!"
echo "  All monitoring components have been removed."
echo "=============================================="
