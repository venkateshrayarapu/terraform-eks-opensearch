#!/bin/bash

# Get the ARN of the bastion host IAM role
BASTION_ROLE_ARN=$(aws iam get-role --role-name opensearch-eks-bastion-role --query 'Role.Arn' --output text)

# Create the aws-auth ConfigMap YAML
cat << EOF > aws-auth-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${BASTION_ROLE_ARN}
      username: bastion-user
      groups:
        - system:masters
    - rolearn: arn:aws:iam::145023112716:role/opensearch-eks-eks-node-role
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

# Apply the ConfigMap
kubectl apply -f aws-auth-cm.yaml

# Test the connection
kubectl get nodes
