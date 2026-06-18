# W10 Lab Submission - RBAC + Gatekeeper

## 📝 Description
Implementation of RBAC roles and Gatekeeper policies for cluster security enforcement.

## ✅ Lab Completion Checklist

### Lab 1.1 - RBAC (3 roles + 3 bindings)
- [ ] Created `rbac/roles.yaml` with 3 roles (developer, sre, viewer)
- [ ] Created `rbac/rolebindings.yaml` with 3 bindings
- [ ] Created `argocd/apps/app-rbac.yaml`
- [ ] Test: `kubectl auth can-i create deployments -n demo --as alice` → yes
- [ ] Test: `kubectl auth can-i create deployments -n kube-system --as alice` → no
- [ ] Test: `kubectl auth can-i get pods --all-namespaces --as bob` → yes
- [ ] Test: `kubectl auth can-i delete nodes --as carol` → no

### Lab 1.2 - Gatekeeper (4 constraints)
- [ ] Created 4 ConstraintTemplates in `gatekeeper/templates/`
- [ ] Created 4 Constraints in `gatekeeper/constraints/`
- [ ] Created `argocd/apps/app-gatekeeper-system.yaml`
- [ ] Created `argocd/apps/app-gatekeeper-templates.yaml`
- [ ] Created `argocd/apps/app-gatekeeper-constraints.yaml`
- [ ] Test: Reject deployment with `:latest` tag
- [ ] Test: Reject deployment without `resources.limits`
- [ ] Test: Reject deployment with `runAsUser: 0`
- [ ] Test: Reject deployment with `hostNetwork: true`
- [ ] Test: Accept valid deployment

### Lab 1.3 - Custom Policy (require owner label)
- [ ] Created `gatekeeper/templates/k8srequiredlabels.yaml`
- [ ] Created `gatekeeper/constraints/require-owner-label.yaml`
- [ ] Test: Reject deployment without `owner` label

### Platform Compliance
- [ ] Updated `app-api/rollout.yaml` with `owner` label
- [ ] Updated `app-api/rollout.yaml` with `runAsUser: 1000`
- [ ] Platform W9 still running healthy after enforcement
- [ ] All ArgoCD applications are `Synced` and `Healthy`

### Repository Setup
- [ ] Forked repository to personal GitHub
- [ ] Updated `repoURL` in `argocd/root.yaml`
- [ ] Updated `repoURL` in `argocd/apps/app-rbac.yaml`
- [ ] Updated `repoURL` in `argocd/apps/app-gatekeeper-templates.yaml`
- [ ] Updated `repoURL` in `argocd/apps/app-gatekeeper-constraints.yaml`

## 🧪 Test Results

### RBAC Tests
```bash
# Paste test results here
kubectl auth can-i create deployments -n demo --as alice
# yes

kubectl auth can-i create deployments -n kube-system --as alice
# no

kubectl auth can-i get pods --all-namespaces --as bob
# yes

kubectl auth can-i delete nodes --as carol
# no
```

### Gatekeeper Tests
```bash
# Paste test results here
kubectl apply -f gatekeeper/test/test-invalid-latest-tag.yaml
# Error from server (Forbidden): ...

# ... (other tests)
```

## 📸 Screenshots (Optional)

### ArgoCD Applications Status
<!-- Screenshot of ArgoCD UI showing all apps Synced -->

### Constraint Status
```bash
kubectl get constraints
# NAME                        AGE
# disallow-latest-tag        5m
# require-resource-limits    5m
# ...
```

## 🔗 Repository Link
- Repository: `https://github.com/<YOUR_USERNAME>/<YOUR_REPO>`
- Branch: `main`

## 📚 Documentation
- [ ] All README files are complete
- [ ] Test files are included
- [ ] Comments explain policy logic

## 🎯 Expected Behavior

### Before Policies
- ❌ Anyone can deploy anything
- ❌ No validation on manifests
- ❌ Easy to cause production incidents

### After Policies
- ✅ RBAC restricts who can do what
- ✅ Gatekeeper validates all manifests
- ✅ Bad manifests are rejected at admission
- ✅ Cluster is more secure and stable

## 💭 Additional Notes
<!-- Add any additional context, challenges faced, or learnings -->

---

## Reviewer Checklist
- [ ] All RBAC tests pass
- [ ] All Gatekeeper tests pass
- [ ] Custom policy works correctly
- [ ] Platform W9 is healthy
- [ ] Code is well-documented
- [ ] Repository is accessible
