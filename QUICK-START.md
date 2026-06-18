# 🚀 Quick Start - W10 Lab

## ⚡ Bắt đầu trong 5 phút

### Bước 1: Fork & Clone
```bash
# Fork repo này về GitHub account của bạn
# Sau đó clone về máy
git clone https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
cd <YOUR_REPO>
```

### Bước 2: Cập nhật repoURL
Mở và sửa các file sau, đổi repoURL thành repo của bạn:

1. `argocd/root.yaml`
2. `argocd/apps/app-rbac.yaml`
3. `argocd/apps/app-gatekeeper-templates.yaml`
4. `argocd/apps/app-gatekeeper-constraints.yaml`

**Tìm và thay thế:**
```yaml
repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

### Bước 3: Commit & Push
```bash
git add .
git commit -m "feat: W10 lab - RBAC + Gatekeeper"
git push origin main
```

### Bước 4: Đảm bảo cluster đang chạy
```bash
# Start cluster (nếu chưa chạy)
minikube start -p w10 --driver=docker

# Use context
kubectl config use-context w10

# Kiểm tra ArgoCD
kubectl get pods -n argocd
```

### Bước 5: Deploy
```bash
# Apply root application
kubectl apply -f argocd/root.yaml

# Đợi ArgoCD sync (2-3 phút)
kubectl get applications -n argocd -w
```

### Bước 6: Test
```bash
# Chạy script test tự động
chmod +x test-lab.sh
./test-lab.sh
```

**Hoặc test thủ công:**

```bash
# Test RBAC
kubectl auth can-i create deployments -n demo --as alice           # yes
kubectl auth can-i create deployments -n kube-system --as alice    # no
kubectl auth can-i get pods --all-namespaces --as bob              # yes
kubectl auth can-i delete nodes --as carol                         # no

# Test Gatekeeper
kubectl apply -f gatekeeper/test/test-invalid-latest-tag.yaml      # reject
kubectl apply -f gatekeeper/test/test-invalid-no-limits.yaml       # reject
kubectl apply -f gatekeeper/test/test-invalid-root-user.yaml       # reject
kubectl apply -f gatekeeper/test/test-invalid-host-network.yaml    # reject
kubectl apply -f gatekeeper/test/test-invalid-no-owner-label.yaml  # reject
kubectl apply -f gatekeeper/test/test-valid-deployment.yaml        # success
```

---

## ✅ Checklist hoàn thành

- [ ] Fork repo về GitHub
- [ ] Cập nhật 4 repoURL
- [ ] Commit & push
- [ ] Deploy qua ArgoCD
- [ ] Test RBAC (4/4 pass)
- [ ] Test Gatekeeper (6/6 pass)
- [ ] Platform W9 vẫn running

---

## 📚 Tài liệu chi tiết

- **W10-LAB-GUIDE.md** - Hướng dẫn đầy đủ từng bước
- **LAB-COMPLETION-SUMMARY.md** - Tổng quan những gì đã làm
- **rbac/README.md** - Chi tiết RBAC
- **gatekeeper/README.md** - Chi tiết Gatekeeper

---

## 🆘 Troubleshooting

### Problem: ArgoCD Application OutOfSync
```bash
# Sync lại thủ công
kubectl -n argocd get applications
argocd app sync <app-name>
```

### Problem: Gatekeeper chưa ready
```bash
# Kiểm tra pods
kubectl get pods -n gatekeeper-system

# Xem logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager
```

### Problem: Test bị reject không đúng
```bash
# Kiểm tra constraints
kubectl get constraints

# Xem chi tiết
kubectl describe K8sRequiredLabels require-owner-label
```

---

## 🎯 Kết quả mong đợi

Sau khi hoàn thành:
```
✅ 3 RBAC roles → 4/4 tests pass
✅ 4 Gatekeeper policies → 5/5 tests reject đúng
✅ 1 Custom policy → 1/1 test reject đúng
✅ Valid deployment → pass
✅ Platform W9 → healthy
✅ All ArgoCD apps → Synced
```

---

**Good luck! 🚀**
