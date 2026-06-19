# Evidence Collection Guide for Challenge

To complete the Challenge submission, capture screenshots or logs for the following 4 criteria:

## 1. payments-dev cô lập đúng (can-i)
Run the following commands to prove `team-payments` can only access their namespace:
```bash
# Check if team-payments can get pods in payments (Should return yes)
kubectl auth can-i get pods -n payments --as team-payments

# Check if team-payments can get pods in demo (Should return no)
kubectl auth can-i get pods -n demo --as team-payments
```

## 2. Quota chặn vượt & LimitRange cấp default
Run the following commands to show quotas and limits in action:
```bash
# Show LimitRange and Quota
kubectl describe limitrange -n payments
kubectl describe quota -n payments

# Try to deploy a pod asking for 5 CPUs (should fail)
kubectl run overquota --image=nginx --requests=cpu=5 -n payments
```

## 3. NetworkPolicy chặn gọi chéo
Test cross-namespace communication using curl pods:
```bash
# Start a curl pod in payments
kubectl run curl-payments -n payments --image=curlimages/curl -- sleep 3600
# Start a curl pod in demo
kubectl run curl-demo -n demo --image=curlimages/curl -- sleep 3600

# Exec into demo pod and try to ping payments (Should timeout/fail due to default-deny ingress)
kubectl exec -it curl-demo -n demo -- curl -m 3 http://payments-app.payments.svc.cluster.local

# Exec into payments pod and try to ping demo (Should timeout/fail due to egress restriction)
kubectl exec -it curl-payments -n payments -- curl -m 3 http://api.demo.svc.cluster.local
```

## 4. App hợp lệ chạy & vi phạm bị constraint chặn
Demonstrate Gatekeeper/Admission rules working:
```bash
# Good deployment should be running
kubectl get pods -n payments

# Try deploying bad image (latest tag) to trigger policy rejection
kubectl create deployment bad-app -n payments --image=nginx:latest
# Output should show Admission Webhook denied the request due to constraint.
```
