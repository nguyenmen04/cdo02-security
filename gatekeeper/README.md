# Gatekeeper - OPA Policy Enforcement

Lab 1.2 & 1.3: Admission policies để chặn manifest xấu tại API server

## Cấu trúc

### templates/
ConstraintTemplates - Định nghĩa logic policy bằng Rego:

1. `k8sdisallowedtagsv2.yaml` - Cấm image tags cụ thể (vd: :latest)
2. `k8srequiredresources.yaml` - Bắt buộc có resources.limits
3. `k8sdisallowroot.yaml` - Cấm chạy với root user (runAsUser: 0)
4. `k8sdisallowhostnetwork.yaml` - Cấm hostNetwork: true
5. `k8srequiredlabels.yaml` - **Custom policy** - Bắt buộc có labels cụ thể

### constraints/
Constraints - Instances của templates, áp dụng policy lên cluster:

1. `disallow-latest-tag.yaml` - Cấm :latest tag
2. `require-resource-limits.yaml` - Bắt buộc cpu/memory limits
3. `disallow-root-user.yaml` - Cấm root
4. `disallow-host-network.yaml` - Cấm host network
5. `require-owner-label.yaml` - **Custom** - Bắt buộc label `owner`

### test/
Test manifests để verify policies:

- `test-valid-deployment.yaml` - Manifest hợp lệ (PASS)
- `test-invalid-latest-tag.yaml` - Vi phạm rule 1 (REJECT)
- `test-invalid-no-limits.yaml` - Vi phạm rule 2 (REJECT)
- `test-invalid-root-user.yaml` - Vi phạm rule 3 (REJECT)
- `test-invalid-host-network.yaml` - Vi phạm rule 4 (REJECT)
- `test-invalid-no-owner-label.yaml` - Vi phạm rule 5 (REJECT)

## Enforcement Action

- `deny` - Enforce mode: Reject manifest vi phạm ngay lập tức
- `warn` - Audit mode: Chỉ warning, không chặn (dùng khi test policy mới)

Để chuyển sang audit mode:
```yaml
spec:
  enforcementAction: warn  # Thay vì deny
```

## Test Policies

```bash
# Test từng manifest vi phạm
kubectl apply -f gatekeeper/test/test-invalid-latest-tag.yaml
# Expected: Error from server (Forbidden): ...disallowed tag...

kubectl apply -f gatekeeper/test/test-invalid-no-limits.yaml
# Expected: Error from server (Forbidden): ...missing required resource limits...

kubectl apply -f gatekeeper/test/test-invalid-root-user.yaml
# Expected: Error from server (Forbidden): ...running as root...

kubectl apply -f gatekeeper/test/test-invalid-host-network.yaml
# Expected: Error from server (Forbidden): ...hostNetwork...

kubectl apply -f gatekeeper/test/test-invalid-no-owner-label.yaml
# Expected: Error from server (Forbidden): ...missing required labels...

# Test manifest hợp lệ
kubectl apply -f gatekeeper/test/test-valid-deployment.yaml
# Expected: deployment.apps/test-valid created
```

## Deployment

Gatekeeper được deploy qua 3 ArgoCD Applications:
1. `app-gatekeeper-system.yaml` - Cài Gatekeeper controller (sync-wave: -1)
2. `app-gatekeeper-templates.yaml` - Deploy ConstraintTemplates (sync-wave: 0)
3. `app-gatekeeper-constraints.yaml` - Deploy Constraints (sync-wave: 1)

## Kiểm tra status

```bash
# Gatekeeper pods
kubectl get pods -n gatekeeper-system

# ConstraintTemplates
kubectl get constrainttemplates

# Constraints
kubectl get constraints

# Chi tiết một constraint
kubectl describe K8sRequiredLabels require-owner-label
```

## Tài liệu tham khảo

- [Gatekeeper Docs](https://open-policy-agent.github.io/gatekeeper/website/docs/)
- [Gatekeeper Library](https://github.com/open-policy-agent/gatekeeper-library)
- [Rego Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
