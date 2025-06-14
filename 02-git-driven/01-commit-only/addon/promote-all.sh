#!/bin/bash

# Script to promote through UAT and Prod stages
# Run this from the kargo-examples/02-git-driven/01-commit-only directory

echo "🚀 Starting promotion process for UAT and Prod stages..."
echo

# Apply UAT promotion
echo "📦 Creating UAT promotion..."
kubectl apply -f promote-uat.yaml

echo "⏳ Waiting for UAT promotion to complete..."
kubectl wait --for=condition=Succeeded promotion/uat-promotion-manual -n kargo-demo-09 --timeout=300s

if [ $? -eq 0 ]; then
    echo "✅ UAT promotion succeeded!"
    
    # Check if 09/stage/uat branch was created
    echo "🔍 Checking if UAT branch was created..."
    git ls-remote https://github.com/cyberslot/kargo-demo-gitops.git | grep "09/stage/uat"
    
    # Wait a moment for Argo CD to sync
    echo "⏳ Waiting for Argo CD to detect UAT branch..."
    sleep 10
    
    # Check UAT application status
    echo "📋 UAT Application status:"
    kubectl get application kargo-demo-09-uat -n argocd -o jsonpath='{.status.sync.status}' && echo
    
    # Now promote to Prod (note: prod requires uat to be completed first)
    echo
    echo "📦 Creating Prod promotion..."
    kubectl apply -f promote-prod.yaml
    
    echo "⏳ Waiting for Prod promotion to complete..."
    kubectl wait --for=condition=Succeeded promotion/prod-promotion-manual -n kargo-demo-09 --timeout=300s
    
    if [ $? -eq 0 ]; then
        echo "✅ Prod promotion succeeded!"
        
        # Check if 09/stage/prod branch was created
        echo "🔍 Checking if Prod branch was created..."
        git ls-remote https://github.com/cyberslot/kargo-demo-gitops.git | grep "09/stage/prod"
        
        # Wait a moment for Argo CD to sync
        echo "⏳ Waiting for Argo CD to detect Prod branch..."
        sleep 10
        
        # Check Prod application status
        echo "📋 Prod Application status:"
        kubectl get application kargo-demo-09-prod -n argocd -o jsonpath='{.status.sync.status}' && echo
        
        echo
        echo "🎉 All promotions completed! Final status:"
        kubectl get applications -n argocd | grep kargo-demo-09
        
    else
        echo "❌ Prod promotion failed or timed out"
        kubectl describe promotion/prod-promotion-manual -n kargo-demo-09
    fi
    
else
    echo "❌ UAT promotion failed or timed out"
    kubectl describe promotion/uat-promotion-manual -n kargo-demo-09
fi

echo
echo "📊 Current promotion status:"
kubectl get promotions -n kargo-demo-09

echo
echo "🌿 Current Git branches:"
git ls-remote https://github.com/cyberslot/kargo-demo-gitops.git | grep "09/stage"
