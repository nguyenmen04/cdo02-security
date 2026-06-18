# RBAC - Role-Based Access Control

Lab 1.1: Phân quyền 3 vai trò cho 3 users

## Cấu trúc

- `roles.yaml` - Định nghĩa 3 roles:
  - `developer` (Role) - CRUD workloads trong namespace `demo`
  - `sre` (ClusterRole) - Quản lý pods toàn cụm
  - `viewer` (ClusterRole) - Chỉ đọc toàn cụm

- `rolebindings.yaml` - Gắn roles cho users:
  - `alice` → `developer` role
  - `bob` → `sre` role
  - `carol` → `viewer` role

## Test

```bash
# Alice có thể tạo deployment trong demo
kubectl auth can-i create deployments -n demo --as alice
# yes

# Alice không thể tạo deployment trong kube-system
kubectl auth can-i create deployments -n kube-system --as alice
# no

# Bob có thể xem pods ở mọi namespace
kubectl auth can-i get pods --all-namespaces --as bob
# yes

# Carol không thể xóa nodes
kubectl auth can-i delete nodes --as carol
# no
```

## Deployment

RBAC resources được deploy qua ArgoCD Application: `app-rbac.yaml`
