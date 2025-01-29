resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = kubernetes_namespace.ingress_nginx.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      controller = {
        service = {
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"                     = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
            "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"         = "tcp"
            "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"               = "443"
            "service.beta.kubernetes.io/aws-load-balancer-proxy-protocol"          = "*"
          }
          targetPorts = {
            http  = "http"
            https = "https"
          }
        }
        config = {
          "use-proxy-protocol" = "true"
          "use-forwarded-headers" = "true"
          "ssl-protocols" = "TLSv1.2 TLSv1.3"
          "proxy-buffer-size" = "16k"
          "proxy-buffers" = "4 16k"
          "proxy-ssl-name" = "vpc-opensearch-cluster-ckv7i4qcfrsf5elbt7i2abh23e.us-west-2.es.amazonaws.com"
          "proxy-ssl-server-name" = "on"
          "proxy-ssl-verify" = "false"
          "enable-real-ip" = "true"
          "real-ip-header" = "proxy_protocol"
          "proxy-ssl-protocols" = "TLSv1.2 TLSv1.3"
        }
        metrics = {
          enabled = true
        }
      }
    })
  ]
}

# OpenSearch Dashboard Ingress
resource "kubernetes_ingress_v1" "opensearch_dashboard_ingress" {
  metadata {
    name      = "opensearch-dashboard-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class"                          = "nginx"
      "nginx.ingress.kubernetes.io/backend-protocol"         = "HTTPS"
      "nginx.ingress.kubernetes.io/proxy-body-size"          = "50m"
      "nginx.ingress.kubernetes.io/proxy-buffer-size"        = "16k"
      "nginx.ingress.kubernetes.io/proxy-connect-timeout"    = "300"
      "nginx.ingress.kubernetes.io/proxy-read-timeout"       = "300"
      "nginx.ingress.kubernetes.io/proxy-send-timeout"       = "300"
      "nginx.ingress.kubernetes.io/ssl-passthrough"          = "true"
      "nginx.ingress.kubernetes.io/ssl-verify"               = "false"
      "nginx.ingress.kubernetes.io/upstream-vhost"           = "vpc-opensearch-cluster-ckv7i4qcfrsf5elbt7i2abh23e.us-west-2.es.amazonaws.com"
      "nginx.ingress.kubernetes.io/proxy-ssl-verify"         = "false"
      "nginx.ingress.kubernetes.io/proxy-ssl-name"           = "vpc-opensearch-cluster-ckv7i4qcfrsf5elbt7i2abh23e.us-west-2.es.amazonaws.com"
    }
  }

  spec {
    rule {
      host = var.dashboard_domain

      http {
        path {
          path = "/"
          path_type = "Prefix"
          
          backend {
            service {
              name = "opensearch-cluster-dashboards"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }
}

# Security Group for Ingress
resource "aws_security_group" "ingress" {
  name        = "${var.cluster_name}-ingress-sg"
  description = "Security group for Nginx ingress controller"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-ingress-sg"
  }
}
