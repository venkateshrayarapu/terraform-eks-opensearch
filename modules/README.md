# OpenSearch and EKS Cluster Connection Guide

This guide provides instructions on how to connect to your OpenSearch dashboard and EKS cluster.

## Prerequisites

- AWS CLI installed and configured
- kubectl installed
- AWS IAM credentials with appropriate permissions

## Connecting to OpenSearch Dashboard

1. Get the OpenSearch dashboard endpoint:
```bash
terraform output -module=opensearch dashboard_endpoint
```

2. Configure your AWS credentials:
```bash
aws configure
```

3. Generate temporary credentials for OpenSearch:
```bash
aws sts assume-role --role-arn $(terraform output -module=opensearch master_user_arn) --role-session-name opensearch-session
```

4. Access the OpenSearch dashboard using the endpoint URL in your browser
   - Use the temporary credentials from the previous step
   - The dashboard URL format: https://<domain-endpoint>/_dashboards/

## Connecting to EKS Cluster

1. Update your kubeconfig:
```bash
aws eks update-kubeconfig --name $(terraform output -module=eks cluster_name) --region <your-aws-region>
```

2. Verify the connection:
```bash
kubectl get nodes
```

3. Get cluster information:
```bash
kubectl cluster-info
```

## Connecting via Bastion Host

### Prerequisites
- SSH key pair (`bastion-key-new.pem`)
- Bastion host public IP: 54.244.189.125

### Configuration Files

1. **configure-eks-auth.sh** - Configures EKS authentication:
```bash
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
```

2. **setup-opensearch-proxy.sh** - Sets up OpenSearch dashboard proxy:
```bash
#!/bin/bash

# Install socat if not already installed
sudo apt-get update
sudo apt-get install -y socat

# Start socat to forward port 5601 to OpenSearch dashboard
socat TCP-LISTEN:5601,fork TCP:vpc-opensearch-cluster-ckv7i4qcfrsf5elbt7i2abh23e.us-west-2.es.amazonaws.com:443
```

### Accessing OpenSearch Dashboard

1. Connect to the dashboard through bastion host:
   ```
   https://54.244.189.125:5601/_dashboards/
   ```

2. If the proxy is not running, SSH into the bastion host and start it:
   ```bash
   ssh -i bastion-key-new.pem ubuntu@54.244.189.125
   ./setup-opensearch-proxy.sh
   ```

### Security Group Configuration

The bastion host security group includes:
- Inbound port 22 (SSH)
- Inbound port 5601 (OpenSearch Dashboard)
- Outbound port 443 (HTTPS)
- All outbound traffic

### IAM Role Configuration

The bastion host IAM role (`opensearch-eks-bastion-role`) has permissions for:
- eks:DescribeCluster
- eks:ListClusters
- eks:AccessKubernetesApi
- sts:GetCallerIdentity
- iam:GetRole
- iam:ListRoles

### Troubleshooting Bastion Host Connection

1. Verify SSH access:
   ```bash
   ssh -i bastion-key-new.pem ubuntu@54.244.189.125
   ```

2. Check proxy status:
   ```bash
   ps aux | grep socat
   ```

3. Verify security group rules:
   ```bash
   aws ec2 describe-security-groups --group-ids sg-06f732025722858dd
   ```

4. Test OpenSearch connectivity from bastion:
   ```bash
   curl -v https://vpc-opensearch-cluster-ckv7i4qcfrsf5elbt7i2abh23e.us-west-2.es.amazonaws.com
   ```

## Troubleshooting

### OpenSearch Connection Issues

1. Check security group rules:
   - Ensure your IP is allowed in the security group
   - Verify VPC endpoint access if using VPC endpoints

2. Verify IAM permissions:
   - Confirm your IAM role has necessary permissions
   - Check if fine-grained access control is properly configured

### EKS Connection Issues

1. Verify AWS credentials:
```bash
aws sts get-caller-identity
```

2. Check node group status:
```bash
kubectl get nodes
aws eks describe-nodegroup --cluster-name $(terraform output -module=eks cluster_name) --nodegroup-name <nodegroup-name>
```

3. View node group logs:
```bash
kubectl logs -n kube-system -l k8s-app=aws-node
```

## Important Security Notes

- Always use IAM roles and temporary credentials
- Enable audit logging for OpenSearch domain
- Regularly rotate credentials and review access patterns
- Use private VPC endpoints when possible
- Keep EKS and OpenSearch versions up to date

## Monitoring

### OpenSearch Monitoring

- Access OpenSearch dashboard metrics at: `_dashboards/app/monitoring`
- Monitor cluster health: `GET _cluster/health`
- Check indices: `GET _cat/indices?v`

### EKS Monitoring

- View cluster metrics: `kubectl top nodes`
- Check pod metrics: `kubectl top pods --all-namespaces`
- Monitor cluster events: `kubectl get events --all-namespaces`

## Support

For additional support:
- AWS OpenSearch Documentation: https://docs.aws.amazon.com/opensearch-service/
- Amazon EKS Documentation: https://docs.aws.amazon.com/eks/
