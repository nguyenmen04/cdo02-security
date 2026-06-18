#!/bin/bash

# Script tự động test Lab 1.1, 1.2, 1.3

set -e

echo "=========================================="
echo "W10 Lab Testing Script"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0

# Function to test command
test_command() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "Testing: $test_name ... "
    
    result=$(eval $command 2>&1 || true)
    
    if [[ "$result" == *"$expected"* ]]; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Expected: $expected"
        echo "  Got: $result"
        ((FAILED++))
    fi
}

echo "=========================================="
echo "Lab 1.1 - RBAC Tests"
echo "=========================================="
echo ""

# RBAC Tests
test_command \
    "Alice can create deployment in demo namespace" \
    "kubectl auth can-i create deployments -n demo --as alice" \
    "yes"

test_command \
    "Alice cannot create deployment in kube-system" \
    "kubectl auth can-i create deployments -n kube-system --as alice" \
    "no"

test_command \
    "Bob can get pods in all namespaces" \
    "kubectl auth can-i get pods --all-namespaces --as bob" \
    "yes"

test_command \
    "Carol cannot delete nodes" \
    "kubectl auth can-i delete nodes --as carol" \
    "no"

echo ""
echo "=========================================="
echo "Lab 1.2 - Gatekeeper Tests"
echo "=========================================="
echo ""

# Wait for Gatekeeper to be ready
echo "Checking if Gatekeeper is ready..."
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=60s

echo ""

# Gatekeeper Tests
test_command \
    "Reject deployment with :latest tag" \
    "kubectl apply -f gatekeeper/test/test-invalid-latest-tag.yaml --dry-run=server" \
    "disallowed tag"

test_command \
    "Reject deployment without resource limits" \
    "kubectl apply -f gatekeeper/test/test-invalid-no-limits.yaml --dry-run=server" \
    "missing required resource limits"

test_command \
    "Reject deployment running as root" \
    "kubectl apply -f gatekeeper/test/test-invalid-root-user.yaml --dry-run=server" \
    "root user"

test_command \
    "Reject deployment with hostNetwork" \
    "kubectl apply -f gatekeeper/test/test-invalid-host-network.yaml --dry-run=server" \
    "hostNetwork"

echo ""
echo "=========================================="
echo "Lab 1.3 - Custom Policy Test"
echo "=========================================="
echo ""

test_command \
    "Reject deployment without owner label" \
    "kubectl apply -f gatekeeper/test/test-invalid-no-owner-label.yaml --dry-run=server" \
    "missing required labels"

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi
