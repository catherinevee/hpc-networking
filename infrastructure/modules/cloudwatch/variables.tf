# Variables for CloudWatch Module

variable "log_groups" {
  description = "Map of CloudWatch log groups to create"
  type = map(object({
    name              = string
    retention_in_days = number
    kms_key_id        = optional(string)
  }))
  default = {}
}

variable "alarms" {
  description = "Map of CloudWatch alarms to create"
  type = map(object({
    alarm_name          = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_description   = string
    alarm_actions       = list(string)
    ok_actions          = list(string)
    treat_missing_data  = string
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
