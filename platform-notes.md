# 🔧 Troubleshooting

Common problems and how to fix them.

---

## How to diagnose any failing pod

This is the first thing to run when something looks wrong:

```bash
# 1. See which pods are not Running
kubectl get pods -n monitoring

# 2. Get detailed info about a specific failing pod
kubectl describe pod <pod-name> -n monitoring
# Look at the "Events:" section at the bottom — it tells you what went wrong

# 3. Read the pod's logs
kubectl logs <pod-name> -n monitoring

# 4. If the pod already crashed, read its previous run's logs
kubectl logs <pod-name> -n monitoring --previous
```

---

## Problem: Loki pod is in CrashLoopBackOff

**Symptom:**
```
loki-0   0/1   CrashLoopBackOff   3
```

**Cause:** Usually the `replication_factor` is set too high for a single node.

**Fix:** Reinstall Loki with the correct single-node flags:
```bash
helm upgrade loki grafana/loki \
  --namespace monitoring \
  --set loki.commonConfig.replication_factor=1 \
  --set loki.storage.type=filesystem \
  --set singleBinary.replicas=1 \
  --set minio.enabled=false \
  --set loki.auth_enabled=false
```

---

## Problem: Grafana shows "Data source connected but no labels received" for Loki

**Symptom:** Grafana's Loki datasource test says "connected" but Explore shows no logs.

**Cause 1:** Wrong Loki URL in Grafana datasource settings.

**Fix:**
1. In Grafana → Connections → Data Sources → Loki
2. Make sure the URL is **exactly**: `http://loki.monitoring.svc.cluster.local:3100`
3. NOT `http://loki:3100` (this fails from other namespaces)
4. NOT `http://localhost:3100` (this only works from outside the cluster)

**Cause 2:** Alloy hasn't collected any logs yet — it can take up to 60 seconds after startup.

**Fix:** Wait 60 seconds, then try the query `{namespace="monitoring"}` again.

---

## Problem: Alloy pod is running but no logs appear in Grafana

**Symptom:** Alloy shows `1/1 Running` but Loki has no data.

**Check Alloy logs for errors:**
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=alloy --tail=50
```

**Check Alloy can reach Loki:**
```bash
# Spin up a temporary pod and test the connection
kubectl run test-curl --rm -it --image=curlimages/curl --restart=Never \
  -n monitoring -- curl http://loki.monitoring.svc.cluster.local:3100/ready
# Expected: ready
```

**If you get "connection refused":** Loki is not ready yet. Wait for `loki-0` to be `Running`.

---

## Problem: Port-forward fails with "address already in use"

**Symptom:**
```
error: unable to listen on port 3000: ... address already in use
```

**Cause:** A previous port-forward is still running.

**Fix:**
```bash
# Kill all kubectl port-forward processes
pkill -f 'kubectl port-forward'

# Wait a second, then re-run
sleep 2
./04-access/access.sh
```

---

## Problem: Port-forward keeps disconnecting

**Symptom:** The port-forward works for a few minutes then drops.

**Cause:** Network timeouts, especially on kind.

**Fix — use nohup to keep it alive:**
```bash
nohup kubectl port-forward svc/monitoring-stack-grafana -n monitoring 3000:80 &>/dev/null &
nohup kubectl port-forward svc/monitoring-stack-kube-prome-prometheus -n monitoring 9090:9090 &>/dev/null &
nohup kubectl port-forward svc/loki -n monitoring 3100:3100 &>/dev/null &
```

---

## Problem: On EKS — LoadBalancer service shows `<pending>` for EXTERNAL-IP

**Symptom:**
```
monitoring-stack-grafana   LoadBalancer   10.100.x.x   <pending>   80:31000/TCP
```

**Cause 1:** AWS Load Balancer Controller is not installed.
```bash
kubectl get pods -n kube-system | grep aws-load-balancer
```
If nothing shows, follow the [AWS Load Balancer Controller install guide](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html).

**Cause 2:** The EKS node IAM role is missing EC2/ELB permissions.
Check the IAM role attached to your EKS nodes and ensure it has the `AmazonEKSWorkerNodePolicy` and load balancer policies.

---

## Problem: `helm install` fails with "cannot re-use a name that is still in use"

**Symptom:**
```
Error: cannot re-use a name that is still in use
```

**Cause:** You're running `helm install` but the release already exists.

**Fix:** Use `helm upgrade --install` (which installs OR upgrades):
```bash
helm upgrade --install monitoring-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.service.type=ClusterIP \
  --set grafana.service.type=ClusterIP \
  --set alertmanager.service.type=ClusterIP
```

Or uninstall first:
```bash
helm uninstall monitoring-stack -n monitoring
```

---

## Problem: `kubectl get pods` shows ImagePullBackOff

**Symptom:**
```
loki-0   0/1   ImagePullBackOff   0
```

**Cause:** Docker Hub rate limit hit, or no internet access.

**Fix:**
```bash
# Check what the exact error is
kubectl describe pod loki-0 -n monitoring
# Look at Events — it will say something like:
# "ratelimit: You have reached your pull rate limit"

# Wait a few minutes and the pod will retry automatically
# Or manually delete the pod to force a retry:
kubectl delete pod loki-0 -n monitoring
```

---

## Still stuck?

Run this command and read the Events section carefully:
```bash
kubectl describe pod <pod-name> -n monitoring
```

It almost always tells you exactly what went wrong.
