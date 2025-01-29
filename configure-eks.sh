#!/bin/bash

# Configure AWS CLI with the region
aws configure set region us-west-2
aws configure set output json

# Update kubeconfig for EKS
aws eks update-kubeconfig --name opensearch-eks --region us-west-2

# Test the connection
kubectl get nodes
