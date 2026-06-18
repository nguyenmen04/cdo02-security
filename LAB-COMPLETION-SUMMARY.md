# Lab W10 - Hoàn thành Summary

## ✅ Đã hoàn thành

### Lab 1.1 - RBAC (3 roles + 3 bindings)

**Files đã tạo:**
- ✅ `rbac/roles.yaml` - 3 roles:
  - `developer` (Role) - alice có quyền CRUD workloads trong namespace `demo`
  - `sre` (ClusterRole) - bob có quyền quản lý pods toàn cụm
  - `viewer` (ClusterRole) - carol chỉ có quyền đọc toàn cụm

- ✅ `rbac/rolebindings.yaml` - 3 bindings gắn roles cho users
- ✅ `argocd/apps/app-rbac.yaml` - ArgoCD Application để deploy RBAC resources

**Nghiệm thu:**
```bash
kubectl auth can-i create deployments -n demo --as alice          # yes ✅
kubectl auth can-i create deployments -n kube-system --as alice   # no  ✅
kubectl auth can-i get pods --all-namespaces --as bob             # yes ✅
kubectl auth can-i delete nodes --as carol                        # no  ✅
```

---

### Lab 1.2 - Gatekeeper (4 constraints bắt buộc)

**ConstraintTemplates (Rego logic):**
- ✅ `gatekeeper/templates/k8sdisallowedtagsv2.yaml` - Cấm tags cụ thể
- ✅ `gatekeeper/templates/k8srequiredresources.yaml` - Bắt buộc resources.limits
- ✅ `gatekeeper/templates/k8sdisallowroot.yaml` - Cấm runAsUser: 0
- ✅ `gatekeeper/templates/k8sdisallowhostnetwork.yaml` - Cấm hostNetwork

**Constraints (Policy instances):**
- ✅ `gatekeeper/constraints/disallow-latest-tag.yaml` - Rule 1: Cấm :latest
- ✅ `gatekeeper/constraints/require-resource-limits.yaml` - Rule 2: Bắt buộc limits
- ✅ `gatekeeper/constraints/disallow-root-user.yaml` - Rule 3: Cấm root
- ✅ `gatekeeper/constraints/disallow-host-network.yaml` - Rule 4: Cấm hostNetwork

**ArgoCD Applications:**
- ✅ `argocd/apps/app-gatekeeper-system.yaml` - Cài Gatekeeper controller
- ✅ `argocd/apps/app-gatekeeper-templates.yaml` - Deploy templates
- ✅ `argocd/apps/app-gatekeeper-constraints.yaml` - Deploy constraints

**Nghiệm thu:**
```bash
# Các manifest vi phạm phải bị reject:
kubectl apply -f gatekeeper/test/test-invalid-latest-tag.yaml      # ❌ reject
kubectl apply -f gatekeeper/test/test-invalid-no-limits.yaml       # ❌ reject
kubectl apply -f gatekeeper/test/test-invalid-root-user.yaml       # ❌ reject
kubectl apply -f gatekeeper/test/test-invalid-host-network.yaml    # ❌ reject

# Manifest hợp lệ phải pass:
kubectl apply -f gatekeeper/test/test-valid-deployment.yaml        # ✅ pass
```

---

### Lab 1.3 - Custom Policy (Bắt buộc label owner)

**ConstraintTemplate:**
- ✅ `gatekeeper/templates/k8srequiredlabels.yaml` - Custom Rego logic kiểm tra labels

**Constraint:**
- ✅ `gatekeeper/constraints/require-owner-label.yaml` - Bắt buộc label `owner`

**Nghiệm thu:**
```bash
# Deployment thiếu label owner phải bị reject:
kubectl apply -f gatekeeper/test/test-invalid-no-owner-label.yaml  # ❌ reject
```

---

### Cập nhật Platform W9

**Files đã cập nhật:**
- ✅ `app-api/rollout.yaml` - Đã thêm:
  - Label `owner: team-platform`
  - SecurityContext `runAsUser: 1000` (non-root)
  - Đảm bảo tuân thủ tất cả 5 policies

---

### Test & Documentation

**Test files:**
- ✅ `gatekeeper/test/test-valid-deployment.yaml` - Manifest hợp lệ
- ✅ `gatekeeper/test/test-invalid-*.yaml` - 5 manifests vi phạm

**Documentation:**
- ✅ `W10-LAB-GUIDE.md` - Hướng dẫn chi tiết làm lab
- ✅ `rbac/README.md` - Docs cho RBAC
- ✅ `gatekeeper/README.md` - Docs cho Gatekeeper
- ✅ `test-lab.sh` - Script tự động test

---

## 📋 Checklist trước khi nộp

### 1. Cập nhật repoURL
Đổi `repoURL` trong các files sau thành repo của bạn:
- [ ] `argocd/root.yaml`
- [ ] `argocd/apps/app-rbac.yaml`
- [ ] `argocd/apps/app-gatekeeper-templates.yaml`
- [ ] `argocd/apps/app-gatekeeper-constraints.yaml`

### 2. Commit & Push
```bash
git add .
git commit -m "feat: add RBAC and Gatekeeper policies for W10 lab"
git push origin main
```

### 3. Deploy
```bash
# Apply root app
kubectl apply -f argocd/root.yaml

# Đợi sync
kubectl get applications -n argocd -w
```

### 4. Verify
```bash
# Chạy script test tự động
chmod +x test-lab.sh
./test-lab.sh

# Hoặc test thủ công theo W10-LAB-GUIDE.md
```

---

## 🎯 Kết quả mong đợi

Sau khi hoàn thành:
- ✅ 3 RBAC roles hoạt động đúng (4/4 tests pass)
- ✅ 4 Gatekeeper constraints enforce đúng (5/5 tests pass)
- ✅ 1 custom policy hoạt động (1/1 test pass)
- ✅ Platform W9 vẫn running healthy
- ✅ Tất cả resources được quản lý qua GitOps (ArgoCD Synced)

---

## 📚 Cấu trúc thư mục cuối cùng

```
.
├── argocd/
│   ├── apps/
│   │   ├── app-rbac.yaml                       # NEW
│   │   ├── app-gatekeeper-system.yaml          # NEW
│   │   ├── app-gatekeeper-templates.yaml       # NEW
│   │   ├── app-gatekeeper-constraints.yaml     # NEW
│   │   └── ... (existing apps)
│   └── root.yaml                               # (updated repoURL)
│
├── rbac/                                        # NEW
│   ├── roles.yaml
│   ├── rolebindings.yaml
│   └── README.md
│
├── gatekeeper/                                  # NEW
│   ├── templates/
│   │   ├── k8sdisallowedtagsv2.yaml
│   │   ├── k8srequiredresources.yaml
│   │   ├── k8sdisallowroot.yaml
│   │   ├── k8sdisallowhostnetwork.yaml
│   │   └── k8srequiredlabels.yaml             # Custom
│   ├── constraints/
│   │   ├── disallow-latest-tag.yaml
│   │   ├── require-resource-limits.yaml
│   │   ├── disallow-root-user.yaml
│   │   ├── disallow-host-network.yaml
│   │   └── require-owner-label.yaml           # Custom
│   ├── test/
│   │   ├── test-valid-deployment.yaml
│   │   ├── test-invalid-latest-tag.yaml
│   │   ├── test-invalid-no-limits.yaml
│   │   ├── test-invalid-root-user.yaml
│   │   ├── test-invalid-host-network.yaml
│   │   └── test-invalid-no-owner-label.yaml
│   └── README.md
│
├── app-api/
│   └── rollout.yaml                            # (updated với owner label + securityContext)
│
├── W10-LAB-GUIDE.md                            # NEW
├── LAB-COMPLETION-SUMMARY.md                   # NEW (this file)
└── test-lab.sh                                 # NEW
```

---

## 🚀 Next Steps

1. **Fork repo** về GitHub của bạn
2. **Cập nhật repoURL** trong 4 files ArgoCD
3. **Commit & push** code
4. **Deploy** qua ArgoCD: `kubectl apply -f argocd/root.yaml`
5. **Test** bằng `./test-lab.sh` hoặc theo hướng dẫn trong `W10-LAB-GUIDE.md`
6. **Verify** platform W9 vẫn running
7. **Nộp bài** với repo link

---

## 💡 Tips

- Nếu muốn test policy mà không chặn → dùng `enforcementAction: warn` thay vì `deny`
- Nếu policy chặn pods hệ thống → thêm `excludedNamespaces` trong constraint
- Dùng `kubectl describe constraint <name>` để xem chi tiết vi phạm
- Kiểm tra Gatekeeper logs: `kubectl logs -n gatekeeper-system -l control-plane=controller-manager`

---

**🎉 Chúc bạn hoàn thành lab thành công!**
