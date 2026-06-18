# 📋 Policy Explanation - Tại sao cần các policies này?

## 🎯 Mục tiêu chung

Cluster Kubernetes mặc định **KHÔNG có bất kỳ ràng buộc nào**. Điều này rất nguy hiểm vì:
- Developer có thể deploy bất cứ thứ gì
- Không kiểm soát được quality và security
- Tai nạn production dễ xảy ra

**Giải pháp**: Implement 2 lớp kiểm soát:
1. **RBAC** - Kiểm soát "ai làm gì"
2. **Admission Policies** - Kiểm soát "cái gì như thế nào"

---

## 🔐 RBAC Policies

### Policy 1: Developer Role (alice)
**Quyền**: CRUD workloads trong namespace `demo` only

**Tại sao?**
- Developer cần deploy/update code của họ
- NHƯNG chỉ trong sandbox namespace (`demo`)
- Không được chạm vào production hoặc hệ thống

**Tình huống thực tế:**
```
❌ BAD: Alice nhầm lẫn gõ:
   kubectl delete deployment -n prod payment-service
   → Service production sập

✅ GOOD: Alice không có quyền trong namespace prod
   → Command bị reject ngay
```

### Policy 2: SRE Role (bob)
**Quyền**: Xem và thao tác pods toàn cụm

**Tại sao?**
- SRE cần debug pods ở mọi namespace
- Cần restart/scale pods khi có incident
- NHƯNG không nên có full admin (delete nodes, etc.)

**Tình huống thực tế:**
```
✅ GOOD: Production có incident lúc 2h sáng
   Bob ssh vào, check logs pods ở namespace prod
   → Nhanh chóng identify issue
```

### Policy 3: Viewer Role (carol)
**Quyền**: Chỉ đọc toàn cụm

**Tại sao?**
- Security team cần audit
- Business team cần view metrics
- NHƯNG tuyệt đối không được sửa gì

**Tình huống thực tế:**
```
✅ GOOD: Audit team cần kiểm tra compliance
   Carol xem configs, resources
   → Thu thập report nhưng không thay đổi gì
```

---

## 🚫 Gatekeeper Admission Policies

### Policy 1: Cấm image tag `:latest`

**Rego code:**
```rego
violation[{"msg": msg}] {
  container := input_containers[_]
  image := container.image
  [_, tag] := split(image, ":")
  tag == "latest"
  msg := sprintf("Container '%s' uses disallowed tag ':latest'", [container.name])
}
```

**Tại sao?**
- Tag `:latest` luôn trỏ đến version mới nhất
- Deploy hôm nay OK, deploy ngày mai có thể broken
- Không reproducible, không rollback được

**Tình huống thực tế:**
```
❌ BAD: 
   deployment.yaml: image: nginx:latest
   Tháng 1: nginx:latest = 1.20 → OK
   Tháng 3: nginx:latest = 1.22 → Breaking change → Production down

✅ GOOD:
   deployment.yaml: image: nginx:1.20.2
   → Luôn reproducible, biết chính xác version đang chạy
```

### Policy 2: Bắt buộc `resources.limits`

**Rego code:**
```rego
violation[{"msg": msg}] {
  container := input_containers[_]
  not container.resources.limits
  msg := sprintf("Container '%s' has no resource limits", [container.name])
}
```

**Tại sao?**
- Không có limits → pod có thể ăn hết CPU/RAM của node
- Một pod "hư" có thể kill cả node
- Tất cả pods khác trên node đó bị evict

**Tình huống thực tế:**
```
❌ BAD:
   Pod A có memory leak, không có limits
   → Ăn dần RAM: 1GB → 4GB → 8GB → 16GB
   → Node hết RAM → OOM Killer → 20 pods khác die

✅ GOOD:
   Pod A có limits memory: 512Mi
   → Memory leak → Pod A bị OOM kill → chỉ 1 pod restart
   → Các pods khác không bị ảnh hưởng
```

### Policy 3: Cấm `runAsUser: 0` (root)

**Rego code:**
```rego
violation[{"msg": msg}] {
  container := input_containers[_]
  container.securityContext.runAsUser == 0
  msg := sprintf("Container '%s' runs as root (uid 0)", [container.name])
}
```

**Tại sao?**
- Chạy root = có mọi quyền trong container
- Nếu container bị hack → attacker có root privilege
- Container escape → attacker có root trên node

**Tình huống thực tế:**
```
❌ BAD:
   Container chạy root, có RCE vulnerability
   Attacker exploit → chạy được code trong container với root
   → Có thể mount host filesystem, read secrets, escape ra node

✅ GOOD:
   Container chạy user 1000 (non-root)
   Attacker exploit → chạy được code nhưng chỉ có quyền user 1000
   → Không đọc được nhiều file, khó escape
```

### Policy 4: Cấm `hostNetwork: true`

**Rego code:**
```rego
violation[{"msg": msg}] {
  input.review.object.spec.hostNetwork
  msg := "Using hostNetwork: true is not allowed"
}
```

**Tại sao?**
- `hostNetwork: true` → pod dùng chung network namespace với node
- Pod có thể sniff traffic của node
- Pod có thể bind vào ports đặc biệt của node

**Tình huống thực tế:**
```
❌ BAD:
   Malicious pod enable hostNetwork
   → Có thể sniff traffic của kubelet (port 10250)
   → Đánh cắp credentials, tokens
   → Lateral movement tấn công các pods khác

✅ GOOD:
   Pod bị reject nếu có hostNetwork
   → Bắt buộc dùng network namespace riêng
   → Isolated, không sniff được traffic
```

### Policy 5 (Custom): Bắt buộc label `owner`

**Rego code:**
```rego
violation[{"msg": msg}] {
  provided := {label | input.review.object.metadata.labels[label]}
  required := {label | label := input.parameters.labels[_]}
  missing := required - provided
  count(missing) > 0
  msg := sprintf("Missing required labels: %v", [missing])
}
```

**Tại sao?**
- Trong cluster lớn, hàng trăm deployments
- Không biết deployment nào của team nào
- Khi có incident, không biết contact ai

**Tình huống thực tế:**
```
❌ BAD:
   Có 200 deployments, không có label owner
   Production down lúc 3h sáng
   → Không biết deployment "payment-processor" của team nào
   → Mất 30 phút tìm người

✅ GOOD:
   Tất cả deployment có label owner: team-payment
   Production down → Ngay lập tức biết contact team Payment
   → Resolve nhanh hơn
```

---

## 🔄 Flow hoàn chỉnh

Khi developer gõ `kubectl apply -f deployment.yaml`:

```
1. Authentication
   ├─ "Bạn là ai?"
   └─ Check certificate/token → OK, bạn là alice

2. Authorization (RBAC)
   ├─ "Bạn có quyền create deployment trong namespace demo không?"
   └─ Check RoleBinding → alice có role developer → OK

3. Admission (Gatekeeper)
   ├─ "Manifest này có hợp lệ không?"
   ├─ Check constraint 1: image tag không phải :latest? → OK
   ├─ Check constraint 2: có resources.limits? → OK
   ├─ Check constraint 3: không chạy root? → OK
   ├─ Check constraint 4: không dùng hostNetwork? → OK
   └─ Check constraint 5: có label owner? → OK

4. Persist to etcd
   └─ Lưu vào cluster → Deployment được tạo
```

Nếu **BẤT KỲ check nào FAIL** → Reject ngay, không tạo resource.

---

## 📊 So sánh: Có Policy vs Không có Policy

| Tình huống | Không có Policy | Có Policy |
|-----------|----------------|-----------|
| Junior deploy image:latest | ✅ Deploy OK → Production broken sau 1 tháng | ❌ Reject → Bắt buộc pin version |
| Pod không có limits | ✅ Deploy OK → OOM kill 20 pods khác | ❌ Reject → Bắt buộc set limits |
| Deploy chạy root | ✅ Deploy OK → Container escape dễ | ❌ Reject → Bắt buộc non-root |
| Deploy hostNetwork | ✅ Deploy OK → Sniff traffic được | ❌ Reject → Bắt buộc isolated network |
| Deploy không có owner | ✅ Deploy OK → Incident không biết contact ai | ❌ Reject → Bắt buộc có owner |
| Alice xóa prod namespace | ✅ Xóa OK → Service down 15 phút | ❌ Forbidden → Không có quyền |

---

## 🎯 Kết luận

**Trước khi có policies:**
- Cluster = chợ, ai muốn làm gì cũng được
- Developer có full quyền → dễ tai nạn
- Không kiểm soát quality → manifest xấu vào production

**Sau khi có policies:**
- Cluster = được kiểm soát chặt chẽ
- RBAC phân quyền rõ ràng → giảm tai nạn do sai quyền
- Gatekeeper chặn manifest xấu → chỉ manifest tốt vào production

**ROI (Return on Investment):**
- Mất 2h implement policies
- Tiết kiệm hàng chục giờ debug incidents
- Giảm drastically production downtime
- Tăng security posture của cluster

---

**🔒 Remember: Prevention is better than cure!**
