# Application Load Balancer
# Configurado como interno cuando se usa CloudFront, público cuando no
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = var.enable_cloudfront ? true : false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.enable_cloudfront ? aws_subnet.private[*].id : aws_subnet.public[*].id

  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Listener HTTP - Redirige a HTTPS si hay certificado, sino forward directo
# Valida custom header cuando se usa CloudFront
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" || var.domain_name != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" || var.domain_name != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.certificate_arn != "" || var.domain_name != "" ? null : aws_lb_target_group.app.arn
  }
}

# Listener rule para validar custom header de CloudFront (si está habilitado)
resource "aws_lb_listener_rule" "cloudfront_header_validation" {
  count        = var.enable_cloudfront ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }

  condition {
    http_header {
      http_header_name = "X-Custom-Header"
      values           = [var.cloudfront_custom_header_value]
    }
  }
}

# Listener HTTPS - Solo se crea si hay un certificado configurado
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" || var.domain_name != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn != "" ? var.certificate_arn : try(aws_acm_certificate.main[0].arn, "")

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Listener rule HTTPS para validar custom header de CloudFront (si está habilitado)
resource "aws_lb_listener_rule" "cloudfront_header_validation_https" {
  count        = var.enable_cloudfront && (var.certificate_arn != "" || var.domain_name != "") ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }

  condition {
    http_header {
      http_header_name = "X-Custom-Header"
      values           = [var.cloudfront_custom_header_value]
    }
  }
}

# CloudWatch Alarm para ALB
resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when response time is too high"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

