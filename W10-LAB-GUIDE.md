# W10 Lab Guide - RBAC + Gatekeeper

## Tổng quan

Lab này thực hiện:
- **Lab 1.1**: Tạo 3 RBAC roles (developer, sre, viewer) cho 3 users (alice, bob, carol)
- **Lab 1.2**: Cài đặt Gatekeeper và tạo 4 constraints để enforce policies
- **Lab 1.3**: Viết 1 custom ConstraintTemplate (require owner label)

## Yêu cầu trước khi bắt đầu

1. **Fork repo này về GitHub account của bạn**
2. **Cập nhật repoURL** trong các file sau:
   - `argocd/root.yaml` → đổi `repoURL` thành repo của bạn
   - `argocd/apps/app-rbac.yaml` → đổi `repoURL`
   - `argocd/apps/app-gatekeeper-templates.yaml` → đổi `repoURL`
   - `argocd/apps/app-gatekeeper-constraints.yaml` → đổi `repoURL`

3. **Đảm bảo cluster đang chạy**:
```bash
minikube start -p w10 --driver=docker
kubectl config use-context w10
```

4. **ArgoCD đã được cài đặt và running**:
```bash
kubectl -n argocd get pods
```

## Các bước thực hiện

### Bước 1: Commit và push code

```bash
# Thêm tất cả các file mới
git add .

# Commit
git commit -m "feat: add RBAC roles and Gatekeeper policies for W10 lab"

# Push lên repo của bạn
git push origin main
```

### Bước 2: Deploy App of Apps

```bash
# Apply root application
kubectl apply -f argocd/root.yaml

# Chờ ArgoCD sync tất cả applications
kubectl get applications -n argocd -w
```

### Bước 3: Kiểm tra deployment

```bash
# Kiểm tra Gatekeeper đã running
kubectl get pods -n gatekeeper-system

# Kiểm tra ConstraintTemplates đã được tạo
kubectl get constrainttemplates

# Kiểm tra Constraints đã được tạo
kubectl get constraints

# Kiểm tra RBAC roles
kubectl get roles -A
kubectl get clusterroles | grep -E "developer|sre|viewer"

# Kiểm tra RBAC bindings
kubectl get rolebindings -A
kubectl get clusterrolebindings | grep -E "alice|bob|carol"
```

## Lab 1.1 - Nghiệm thu RBAC

Test quyền của 3 users:

```bash
# Test 1: alice có thể create deployment trong namespace demo
kubectl auth can-i create deployments -n demo --as alice
# Expected: yes

# Test 2: alice KHÔNG thể create deployment trong kube-system
kubectl auth can-i create deployments -n kube-system --as alice
# Expected: no

# Test 3: bob có thể get pods ở tất cả namespaces
kubectl auth can-i get pods --all-namespaces --as bob
# Expected: yes

# Test 4: carol KHÔNG thể delete nodes
kubectl auth can-i delete nodes --as carol
# Expected: no
```

Nếu cả 4 test đều đúng → **PASS Lab 1.1** ✅

## Lab 1.2 - Nghiệm thu Gatekeeper

Test các policies bằng cách thử deploy các manifest vi phạm:

### Test 1: Cấm :latest tag

```bash
# Thử deploy với :latest tag → PHẢI bị reject
kubectl apply -f gatekeeper/test/test-invalid-latest-tag.yaml

# Expected output: Error from server (Forbidden): ...disallowed tag 'latest'...
```

### Test 2: Bắt buộc resources.limits

```bash
# Thử deploy thiếu limits → PHẢI bị reject
kubectl apply -f gatekeeper/test/test-invalid-no-limits.yaml

# Expected output: Error from server (Forbidden): ...missing required resource limits...
```

### Test 3: Cấm runAsUser: 0

```bash
# Thử deploy với root user → PHẢI bị reject
kubectl apply -f gatekeeper/test/test-invalid-root-user.yaml

# Expected output: Error from server (Forbidden): ...running as root user...
```

### Test 4: Cấm hostNetwork: true

```bash
# Thử deploy với hostNetwork → PHẢI bị reject
kubectl apply -f gatekeeper/test/test-invalid-host-network.yaml

# Expected output: Error from server (Forbidden): ...hostNetwork: true is not allowed...
```

### Test 5: Deploy hợp lệ phải PASS

```bash
# Deploy manifest hợp lệ → PHẢI thành công
kubectl apply -f gatekeeper/test/test-valid-deployment.yaml

# Expected: deployment.apps/test-valid created
```

Nếu cả 5 test đều đúng → **PASS Lab 1.2** ✅

## Lab 1.3 - Nghiệm thu Custom Policy

Test custom policy "require owner label":

```bash
# Thử deploy thiếu label owner → PHẢI bị reject
kubectl apply -f gatekeeper/test/test-invalid-no-owner-label.yaml

# Expected output: Error from server (Forbidden): ...missing required labels: {"owner"}...
```

Nếu test đúng → **PASS Lab 1.3** ✅

## Kiểm tra Platform W9 vẫn hoạt động

Sau khi enable tất cả policies, đảm bảo platform W9 vẫn chạy bình thường:

```bash
# Kiểm tra tất cả apps trong ArgoCD
kubectl get applications -n argocd

# Kiểm tra API rollout
kubectl get rollout api -n demo

# Kiểm tra pods
kubectl get pods -n demo
kubectl get pods -n monitoring

# Nếu có pod bị reject do vi phạm policy → sửa manifest cho hợp lệ
```

## Audit mode vs Enforce mode

Nếu muốn test policy mà không chặn (chỉ warning):

```bash
# Đổi enforcementAction từ "deny" sang "warn"
# Ví dụ trong file gatekeeper/constraints/disallow-latest-tag.yaml:
spec:
  enforcementAction: warn  # Thay vì deny
```

Sau đó commit và push, ArgoCD sẽ sync lại.

## Troubleshooting

### Problem: Policy chặn cả pods hệ thống

**Solution**: Thêm exclusion trong constraint:

```yaml
spec:
  match:
    excludedNamespaces:
    - kube-system
    - gatekeeper-system
    - monitoring
```

### Problem: ConstraintTemplate không được tạo

**Solution**: Kiểm tra sync-wave và đảm bảo gatekeeper-system đã running trước:

```bash
kubectl get pods -n gatekeeper-system
kubectl logs -n gatekeeper-system -l control-plane=controller-manager
```

### Problem: RBAC test không chạy được

**Solution**: Đảm bảo bạn đang dùng admin context:

```bash
kubectl config current-context
kubectl auth can-i '*' '*' --all-namespaces
# Should return: yes
```

## Deliverable

Để nộp bài, đảm bảo repo của bạn có:

```
✅ rbac/roles.yaml                          # 3 roles
✅ rbac/rolebindings.yaml                   # 3 bindings
✅ gatekeeper/templates/                    # 5 templates
✅ gatekeeper/constraints/                  # 5 constraints
✅ argocd/apps/app-rbac.yaml               # RBAC app
✅ argocd/apps/app-gatekeeper-*.yaml       # 3 Gatekeeper apps
✅ app-api/rollout.yaml đã được cập nhật    # Tuân thủ policies
```

Và pass được:
- ✅ 4 RBAC tests
- ✅ 5 Gatekeeper tests
- ✅ Platform W9 vẫn running healthy

## Tham khảo

- [Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/website/docs/)
- [Gatekeeper Policy Library](https://github.com/open-policy-agent/gatekeeper-library)
- [Rego Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
