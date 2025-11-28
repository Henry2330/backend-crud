# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  count               = var.enable_cloudfront ? 1 : 0
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment} CloudFront Distribution"
  default_root_object = ""
  price_class         = var.cloudfront_price_class
  aliases             = var.domain_name != "" ? [var.domain_name] : []

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALB-${var.project_name}-${var.environment}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.certificate_arn != "" || var.domain_name != "" ? "https-only" : "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Custom-Header"
      value = var.cloudfront_custom_header_value
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "ALB-${var.project_name}-${var.environment}"

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Accept", "Accept-Language", "Content-Type"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = var.enable_https ? "redirect-to-https" : "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  # Cache behavior para contenido estático (si aplica)
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "ALB-${var.project_name}-${var.environment}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = var.enable_https ? "redirect-to-https" : "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = var.cloudfront_geo_restriction_type
      locations        = var.cloudfront_geo_restriction_locations
    }
  }

  viewer_certificate {
    # Si hay certificado ARN, usarlo; si hay dominio, usar el certificado de ACM; si no, usar el certificado por defecto
    acm_certificate_arn      = var.certificate_arn != "" ? var.certificate_arn : (var.domain_name != "" ? try(aws_acm_certificate.main[0].arn, null) : null)
    cloudfront_default_certificate = var.certificate_arn == "" && var.domain_name == "" ? true : false
    ssl_support_method       = var.certificate_arn != "" || var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version = var.certificate_arn != "" || var.domain_name != "" ? "TLSv1.2_2021" : null
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront"
    Environment = var.environment
  }

  # Web Application Firewall (opcional)
  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.main[0].arn : null

  depends_on = [aws_lb.main]
}

# WAF para CloudFront (opcional)
resource "aws_wafv2_web_acl" "main" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.project_name}-${var.environment}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Regla para bloquear IPs maliciosas conocidas
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Regla de AWS Managed Rules
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf"
    Environment = var.environment
  }
}

# CloudWatch Alarms para CloudFront
resource "aws_cloudwatch_metric_alarm" "cloudfront_error_rate" {
  count               = var.enable_cloudfront ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "Alert when CloudFront 5xx error rate is too high"
  alarm_actions       = []

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_cache_hit_rate" {
  count               = var.enable_cloudfront ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-cache-hit-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "Alert when CloudFront cache hit rate is too low"
  alarm_actions       = []

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main[0].id
  }
}

