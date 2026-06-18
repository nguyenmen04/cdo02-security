# 🔧 Troubleshooting Guide

## Common Issues và Solutions

### 1. ArgoCD Application không sync

**Symptoms:**
```
kubectl get applications -n argocd
NAME     SYNC STATUS   HEALTH STATUS
rbac     OutOfSync     Unknown
```

**Possible Causes & Solutions:**

#### Cause 1: Sai repoURL
```bash
# Check repoURL
kubectl get application rbac -n argocd -o yaml | grep repoURL

# Should match your GitHub repo
# Fix: Update repoURL trong file app-rbac.yaml
```

#### Cause 2: Branch không tồn tại
```bash
# Check targetRevision
kubectl get application rbac -n argocd -o yaml | grep targetRevision

# Should be "main" or "master"
# Fix: Đảm bảo branch tồn tại trong repo
```

#### Cause 3: Path không tồn tại
```bash
# Check path
kubectl get application rbac -n argocd -o yaml | grep path

# Should match thư mục trong repo
# Fix: Đảm bảo thư mục rbac/ tồn tại
```

**Force sync:**
```bash
# Sync thủ công
argocd app sync rbac

# Hoặc qua kubectl
kubectl patch application rbac -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

---

### 2. Gatekeeper controller không start

**Symptoms:**
```
kubectl get pods -n gatekeeper-system
NAME                                     READY   STATUS    RESTARTS
gatekeeper-controller-manager-xxx        0/3     Pending   0
```

**Solutions:**

#### Check resources
```bash
# Xem events
kubectl describe pod -n gatekeeper-system gatekeeper-controller-manager-xxx

# Thường là thiếu resources
# Fix: Tăng resources của cluster
minikube config set memory 4096
minikube config set cpus 4
minikube delete -p w10
minikube start -p w10
```

#### Check webhook configuration
```bash
# Kiểm tra webhook
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# Delete và recreate nếu cần
kubectl delete validatingwebhookconfigurations gatekeeper-validating-webhook-configuration
```

---

### 3. ConstraintTemplate không được tạo

**Symptoms:**
```
kubectl get constrainttemplates
No resources found
```

**Causes & Solutions:**

#### Cause 1: Gatekeeper chưa ready
```bash
# Đợi Gatekeeper ready
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=120s
```

#### Cause 2: YAML syntax error
```bash
# Kiểm tra logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager

# Fix: Kiểm tra syntax YAML
kubectl apply -f gatekeeper/templates/k8sdisallowedtagsv2.yaml --dry-run=client
```

#### Cause 3: Sync wave sai thứ tự
```bash
# Check sync wave
kubectl get application -n argocd -o custom-columns=NAME:.metadata.name,WAVE:.metadata.annotations."argocd\.argoproj\.io/sync-wave"

# Đảm bảo:
# gatekeeper-system: -1
# gatekeeper-templates: 0
# gatekeeper-constraints: 1
```

---

### 4. Constraint không enforce (manifest xấu vẫn pass)

**Symptoms:**
```bash
# Test này PHẢI reject nhưng lại pass
kubectl apply -f gatekeeper/test/test-invalid-latest-tag.yaml
# deployment.apps/test-invalid-latest created  (WRONG!)
```

**Causes & Solutions:**

#### Cause 1: Constraint chưa ready
```bash
# Kiểm tra constraint status
kubectl get K8sDisallowedTagsV2 disallow-latest-tag
kubectl describe K8sDisallowedTagsV2 disallow-latest-tag

# Check field "status.byPod"
# Should have entries for each gatekeeper pod
```

#### Cause 2: enforcementAction = warn thay vì deny
```bash
# Check constraint
kubectl get K8sDisallowedTagsV2 disallow-latest-tag -o yaml | grep enforcementAction

# Should be "deny", not "warn"
# Fix: Update constraint, set enforcementAction: deny
```

#### Cause 3: match.kinds không đúng
```bash
# Check match
kubectl get K8sDisallowedTagsV2 disallow-latest-tag -o yaml | grep -A 10 match

# Đảm bảo match Deployment
spec:
  match:
    kinds:
    - apiGroups: ["apps"]
      kinds: ["Deployment"]
```

#### Cause 4: Webhook chưa hoạt động
```bash
# Check webhook
kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration -o yaml

# Kiểm tra field "webhooks[].clientConfig.service"
# Should point to gatekeeper-webhook-service in gatekeeper-system namespace
```

---

### 5. RBAC test không pass

**Symptoms:**
```bash
kubectl auth can-i create deployments -n demo --as alice
# no  (WRONG! Should be yes)
```

**Causes & Solutions:**

#### Cause 1: RoleBinding chưa được tạo
```bash
# Check rolebindings
kubectl get rolebindings -n demo
kubectl get rolebinding alice-developer -n demo

# Nếu không có → ArgoCD chưa sync
kubectl get application rbac -n argocd
```

#### Cause 2: Subject sai
```bash
# Check subject trong binding
kubectl get rolebinding alice-developer -n demo -o yaml | grep -A 5 subjects

# Should be:
# subjects:
# - kind: User
#   name: alice  # ← Phải khớp với --as alice
```

#### Cause 3: RoleRef sai
```bash
# Check roleRef
kubectl get rolebinding alice-developer -n demo -o yaml | grep -A 5 roleRef

# Should point to correct role
# roleRef:
#   kind: Role
#   name: developer
```

---

### 6. Platform W9 bị policies chặn

**Symptoms:**
```
kubectl get rollout api -n demo
# OutOfSync or Degraded

kubectl describe rollout api -n demo
# Error: admission webhook denied the request
```

**Solutions:**

#### Check which policy blocked
```bash
# Get detailed error
kubectl get events -n demo --sort-by='.lastTimestamp' | tail -20

# Usually shows which constraint rejected
```

#### Common fixes

**Missing owner label:**
```yaml
# app-api/rollout.yaml
metadata:
  labels:
    owner: team-platform  # ADD THIS
```

**Missing resources.limits:**
```yaml
# app-api/rollout.yaml
spec:
  template:
    spec:
      containers:
      - resources:
          limits:  # ADD THIS
            cpu: 200m
            memory: 128Mi
```

**Running as root:**
```yaml
# app-api/rollout.yaml
spec:
  template:
    spec:
      securityContext:  # ADD THIS
        runAsUser: 1000
```

---

### 7. Test script báo lỗi

**Symptoms:**
```bash
./test-lab.sh
# bash: ./test-lab.sh: Permission denied
```

**Solution:**
```bash
# Add execute permission
chmod +x test-lab.sh

# Run again
./test-lab.sh
```

---

### 8. Gatekeeper audit violations

**Symptoms:**
```bash
# Có resources vi phạm nhưng không bị reject
kubectl get K8sRequiredLabels require-owner-label -o yaml

# status.violations shows existing resources without owner label
```

**Explanation:**
- Audit mode tìm resources ĐÃ TỒN TẠI vi phạm
- Admission webhook CHỈ chặn resources MỚI

**Solution:**
```bash
# Fix existing resources
kubectl patch deployment <name> -n <namespace> -p '{"metadata":{"labels":{"owner":"team-platform"}}}'

# Hoặc xóa và recreate
kubectl delete deployment <name> -n <namespace>
kubectl apply -f <fixed-manifest>.yaml
```

---

### 9. ArgoCD không thấy changes trong repo

**Symptoms:**
```bash
# Đã push code nhưng ArgoCD không sync
git push origin main
# Everything up-to-date

# But ArgoCD still shows old version
```

**Solutions:**

#### Force refresh
```bash
argocd app get rbac --refresh

# Or trigger sync
argocd app sync rbac
```

#### Check automated sync
```bash
# Check if automated sync is enabled
kubectl get application rbac -n argocd -o yaml | grep -A 5 syncPolicy

# Should have:
# syncPolicy:
#   automated:
#     prune: true
#     selfHeal: true
```

---

### 10. Minikube crash / Out of resources

**Symptoms:**
```
Error: Failed to create pod: nodes are unavailable
```

**Solution:**
```bash
# Increase resources
minikube stop -p w10
minikube config set memory 4096
minikube config set cpus 4
minikube start -p w10

# Or use Docker Desktop Kubernetes instead
```

---

## Debug Commands Cheatsheet

### Check overall status
```bash
# All ArgoCD apps
kubectl get applications -n argocd

# All pods in cluster
kubectl get pods -A

# All constraints
kubectl get constraints

# All RBAC
kubectl get roles,rolebindings -A
kubectl get clusterroles,clusterrolebindings | grep -E "developer|sre|viewer"
```

### Deep dive specific resource
```bash
# Detailed info
kubectl describe <resource> <name> -n <namespace>

# YAML
kubectl get <resource> <name> -n <namespace> -o yaml

# Events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Logs
kubectl logs -n <namespace> <pod-name>
```

### Gatekeeper specific
```bash
# Audit violations
kubectl get constraint -o yaml | grep -A 20 status

# Webhook status
kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration

# Controller logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager --tail=100
```

### RBAC specific
```bash
# Test all verbs
kubectl auth can-i <verb> <resource> -n <namespace> --as <user>

# List all permissions of a user
kubectl auth can-i --list --as alice -n demo
```

---

## 🆘 Still having issues?

1. Read detailed error messages - they usually point to the root cause
2. Check logs - most issues show up in logs
3. Verify YAML syntax - use `--dry-run=client` first
4. Ensure sync-waves are correct - order matters
5. Check resource availability - minikube needs enough memory/CPU

**Debug workflow:**
```
1. Identify which component is failing (ArgoCD? Gatekeeper? RBAC?)
2. Check logs of that component
3. Verify configuration (YAML, repoURL, etc.)
4. Test in isolation (kubectl apply directly first)
5. Check order (sync-waves, dependencies)
```

---

**Remember: Most issues are configuration errors, not bugs!** 🐛
