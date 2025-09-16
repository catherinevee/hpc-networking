# KMS Key for encryption
resource "aws_kms_key" "hpc" {
  description             = "KMS key for HPC infrastructure encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-kms-key"
    Type = "KMS-Key"
  })
}

resource "aws_kms_alias" "hpc" {
  name          = "alias/hpc-${var.environment}-key"
  target_key_id = aws_kms_key.hpc.key_id
}

# SNS Topic for alerts
resource "aws_sns_topic" "hpc_alerts" {
  name = "hpc-${var.environment}-alerts"
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-alerts"
    Type = "SNS-Topic"
  })
}

# CloudWatch Log Group for EFA monitoring
resource "aws_cloudwatch_log_group" "efa_monitoring" {
  name              = "/aws/hpc/${var.environment}/efa"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.hpc.arn
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-efa-logs"
    Type = "CloudWatch-LogGroup"
  })
}

# CloudWatch Alarm for EFA performance
resource "aws_cloudwatch_metric_alarm" "efa_latency" {
  alarm_name          = "hpc-${var.environment}-efa-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EFA_Latency"
  namespace           = "AWS/EFA"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors EFA latency"
  alarm_actions       = [aws_sns_topic.hpc_alerts.arn]
  ok_actions          = [aws_sns_topic.hpc_alerts.arn]
  
  tags = merge(var.common_tags, {
    Name = "hpc-${var.environment}-efa-latency-alarm"
    Type = "CloudWatch-Alarm"
  })
}
