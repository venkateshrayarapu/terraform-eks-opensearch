# Detailed OpenSearch and EKS Setup Guide

## Architecture Overview

This setup consists of the following main components:
1. OpenSearch Domain
2. EKS Cluster
3. Bastion Host
4. VPC and Networking Infrastructure

### Network Architecture

```
                                                    +------------------------+
                                                    |                        |
                                              +---->|  OpenSearch Dashboard  |
                                              |     |                        |
                                              |     +------------------------+
+------------------+     +----------------+    |
|                  |     |                |    |     +------------------------+
|  Public Access   +---->|  Bastion Host  +----+---->|                        |
|                  |     |                |    |     |      EKS Cluster       |
+------------------+     +----------------+    |     |                        |
                                              |     +------------------------+
                                              |
                                              |     +------------------------+
                                              |     |                        |
                                              +---->|  OpenSearch Domain     |
                                                    |                        |
                                                    +------------------------+
```

## Component Details

### 1. VPC Configuration
- Located in: `terraform/modules/vpc/main.tf`
- Features:
  - 2 Public Subnets (for bastion host)
  - 2 Private Subnets (for EKS and OpenSearch)
  - Internet Gateway for public access
  - NAT Gateway for private subnet internet access
  - VPC Endpoints for AWS services

### 2. Bastion Host
- Located in: `terraform/modules/vpc/main.tf`
- Configuration:
  ```hcl
  resource "aws_instance" "bastion" {
    ami           = "ami-0123456789"
    instance_type = "t3.micro"
    subnet_id     = aws_subnet.public[0].id
    key_name      = "bastion-key-new"
    iam_instance_profile = aws_iam_instance_profile.bastion.name
    vpc_security_group_ids = [aws_security_group.bastion.id]
  }
  ```
- Security Group Rules:
  - Inbound:
    - Port 22 (SSH)
    - Port 5601 (OpenSearch Dashboard)
  - Outbound:
    - Port 443 (HTTPS)
    - All traffic

### 3. EKS Cluster
- Located in: `terraform/modules/eks/main.tf`
- Features:
  - Kubernetes version: 1.24
  - Node group configuration:
    - Instance type: t3.medium
    - Desired capacity: 2
    - Max capacity: 4
  - IAM Roles:
    - Cluster role
    - Node group role
    - IRSA (IAM Roles for Service Accounts)

### 4. OpenSearch Domain
- Located in: `terraform/modules/opensearch/main.tf`
- Configuration:
  - Instance type: t3.medium.search
  - Volume size: 100GB
  - Access policies through IAM
  - Fine-grained access control enabled
  - Node-to-node encryption
  - Encryption at rest

## Detailed Component Explanations

### 1. VPC and Network Setup

The VPC is configured with a multi-AZ architecture:

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
    "kubernetes.io/cluster/${var.project_name}" = "shared"
  }
}
```

Key features:
- DNS hostnames and support enabled for internal DNS resolution
- Tagged for EKS cluster integration
- Spans multiple availability zones for high availability

#### Subnet Layout
1. **Private Subnets**:
   - Host EKS nodes and OpenSearch domain
   - No direct internet access
   - Access internet via NAT Gateway
   - Tagged for EKS auto-discovery

2. **Public Subnets**:
   - Host bastion host and load balancers
   - Direct internet access via Internet Gateway
   - Auto-assign public IPs enabled

### 2. EKS Cluster Configuration

The EKS cluster is set up with the following specifications:

```hcl
resource "aws_eks_cluster" "main" {
  name     = var.project_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
```

Features:
- Kubernetes version 1.31
- Both private and public endpoint access
- Comprehensive logging enabled
- Runs in private subnets
- Custom security groups

### 3. OpenSearch Domain Setup

OpenSearch is configured with VPC access and security:

```hcl
resource "aws_security_group" "opensearch" {
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id, var.bastion_security_group_id]
  }
}
```

Security features:
- HTTPS-only access (port 443)
- Access restricted to EKS and bastion security groups
- VPC endpoint for private access

## Component Interactions

### 1. Access Flow for OpenSearch Dashboard

```
Internet -> Bastion Host (5601) -> OpenSearch Domain (443)
```

Detailed flow:
1. User accesses `https://54.244.189.125:5601/_dashboards/`
2. Request hits bastion host on port 5601
3. `socat` on bastion forwards to OpenSearch on port 443
4. OpenSearch processes request and returns response
5. Response follows reverse path back to user

### 2. Access Flow for EKS

```
Internet -> Bastion Host (22) -> EKS API Server
```

Authentication flow:
1. SSH to bastion using key pair
2. Bastion assumes IAM role
3. IAM role allows EKS API access
4. `configure-eks-auth.sh` sets up RBAC

### 3. Security Layers

#### Network Level Security
```
Internet -> Public Subnet -> Private Subnet
                |               |
            Bastion        EKS/OpenSearch
```

Components:
- Bastion: Public subnet with internet access
- EKS & OpenSearch: Private subnets
- NAT Gateway: Outbound internet for private subnets

#### IAM Level Security
```
Bastion Role
  ├── EKS Access Permissions
  │   └── eks:DescribeCluster
  │   └── eks:ListClusters
  │   └── eks:AccessKubernetesApi
  │
  └── OpenSearch Permissions
      └── es:ESHttp*
```

#### Security Group Chain
```
Bastion SG -> EKS SG -> OpenSearch SG
```

Rules:
- Bastion SG:
  - Inbound: 22 (SSH), 5601 (Dashboard)
  - Outbound: All
- EKS SG:
  - Inbound: 443 from Bastion
  - Outbound: All
- OpenSearch SG:
  - Inbound: 443 from Bastion and EKS
  - Outbound: All

## Security Configuration

### 1. IAM Roles and Policies

#### Bastion Host Role (`opensearch-eks-bastion-role`)
```hcl
resource "aws_iam_role_policy" "bastion_eks_access" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:AccessKubernetesApi",
        "sts:GetCallerIdentity",
        "iam:GetRole",
        "iam:ListRoles"
      ]
      Resource = "*"
    }]
  })
}
```

#### EKS Cluster Role
- Permissions for:
  - EKS cluster operations
  - VPC resource management
  - CloudWatch logging

#### EKS Node Role
- Permissions for:
  - Container registry access
  - CloudWatch logging
  - Node management
  - CNI plugin operations

### 2. Security Groups

#### Bastion Security Group
```hcl
resource "aws_security_group" "bastion" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Access Configuration

### 1. EKS Authentication
File: `configure-eks-auth.sh`
```bash
#!/bin/bash
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
```

### 2. OpenSearch Dashboard Access
File: `setup-opensearch-proxy.sh`
```bash
#!/bin/bash
sudo apt-get update
sudo apt-get install -y socat
socat TCP-LISTEN:5601,fork TCP:vpc-opensearch-cluster-ckv7i4qcfrsf5elbt7i2abh23e.us-west-2.es.amazonaws.com:443
```

## Access Flow

1. **SSH to Bastion Host**
   ```bash
   ssh -i bastion-key-new.pem ubuntu@54.244.189.125
   ```

2. **Configure EKS Access**
   ```bash
   ./configure-eks-auth.sh
   aws eks update-kubeconfig --name opensearch-eks --region us-west-2
   ```

3. **Start OpenSearch Proxy**
   ```bash
   ./setup-opensearch-proxy.sh
   ```

4. **Access OpenSearch Dashboard**
   - URL: `https://54.244.189.125:5601/_dashboards/`
   - Authentication: IAM credentials

## Maintenance and Monitoring

### 1. EKS Monitoring
- CloudWatch Container Insights
- Kubernetes dashboard (optional)
- Prometheus and Grafana (optional)

### 2. OpenSearch Monitoring
- Built-in monitoring dashboard
- CloudWatch metrics
- Performance Analyzer

### 3. Bastion Host Monitoring
- CloudWatch agent for system metrics
- VPC Flow Logs
- CloudTrail for API activity

## Backup and Disaster Recovery

### 1. EKS
- etcd backups
- Velero for Kubernetes resources
- Node group auto-scaling

### 2. OpenSearch
- Automated snapshots
- Manual snapshots
- Cross-region replication (optional)

## Security Best Practices

1. **Network Security**
   - Use private subnets for workloads
   - Implement network ACLs
   - Enable VPC Flow Logs

2. **Access Control**
   - Implement least privilege
   - Regular IAM audit
   - Rotate access keys

3. **Monitoring and Logging**
   - Enable CloudTrail
   - Configure CloudWatch alarms
   - Regular security assessments

## Troubleshooting Guide

### Common Issues and Solutions

1. **EKS Connection Issues**
   - Verify IAM roles
   - Check security group rules
   - Validate kubeconfig

2. **OpenSearch Access Issues**
   - Check proxy status
   - Verify security group rules
   - Validate IAM permissions

3. **Bastion Host Issues**
   - Check SSH key permissions
   - Verify network connectivity
   - Review security group rules

## Usage Guide

### Permanent Proxy Configuration

The infrastructure is set up with a permanent proxy configuration:

1. **Security Group Rules**:
```hcl
resource "aws_security_group" "bastion" {
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

2. **IAM Role Permissions**:
```hcl
resource "aws_iam_role_policy" "bastion_eks_access" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:AccessKubernetesApi",
        "sts:GetCallerIdentity",
        "iam:GetRole",
        "iam:ListRoles"
      ]
      Resource = "*"
    }]
  })
}
```

3. **Direct Access**:
- OpenSearch Dashboard is directly accessible at: `https://54.244.189.125:5601/_dashboards/`
- No need to run proxy scripts manually
- Infrastructure handles the routing automatically

### One-Time Setup Tasks

The following tasks only need to be done once after infrastructure creation:

1. **EKS Authentication**:
```bash
ssh -i bastion-key-new.pem ubuntu@54.244.189.125
./configure-eks-auth.sh
```

2. **Verify Access**:
```bash
kubectl get nodes
```

### Regular Usage

1. **Accessing OpenSearch Dashboard**:
- Simply open `https://54.244.189.125:5601/_dashboards/` in your browser
- No additional setup required

2. **Accessing EKS Cluster**:
```bash
ssh -i bastion-key-new.pem ubuntu@54.244.189.125
kubectl get nodes  # or any other kubectl commands
```

### Maintenance Tasks

### 1. Updating EKS Auth

If IAM roles change:
1. Modify `configure-eks-auth.sh`
2. Update ConfigMap:
```bash
kubectl apply -f aws-auth-cm.yaml
```

### 2. Updating OpenSearch Access

If security groups change:
1. Update security group rules
2. Restart proxy if needed:
```bash
pkill socat
./setup-opensearch-proxy.sh
```

### 3. Bastion Host Maintenance

Regular tasks:
1. System updates:
```bash
sudo apt-get update
sudo apt-get upgrade
```

2. Log rotation:
```bash
sudo logrotate -f /etc/logrotate.conf
```

3. Monitor disk space:
```bash
df -h
```
