#!/bin/bash

# Create the aws-auth ConfigMap YAML
cat << EOF > aws-auth-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::145023112716:role/opensearch-eks-bastion-role
      username: bastion-user
      groups:
        - system:masters
    - rolearn: arn:aws:iam::145023112716:role/opensearch-eks-eks-node-role
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

# Update kubeconfig
aws eks update-kubeconfig --name opensearch-eks --region us-west-2

# Apply the ConfigMap
kubectl apply -f aws-auth-cm.yaml

# Test the connection
kubectl get nodes
