locals {
  monitor_enabled = "${var.enabled && length(var.recipients) > 0 ? 1 : 0}"
}

resource "datadog_timeboard" "system" {
  count = "${var.enabled ? 1 : 0}"

  title       = "${var.product_domain} - ${var.cluster} - ${var.environment} - System"
  description = "A generated timeboard for System"

  template_variable {
    default = "${var.cluster}"
    prefix  = "cluster"
    name    = "cluster"
  }

  template_variable {
    default = "${var.environment}"
    name    = "environment"
    prefix  = "environment"
  }

  graph {
    title     = "CPU Utilization (Rollup: max)"
    viz       = "timeseries"
    autoscale = true

    request {
      q          = "avg:ecs.fargate.cpu.percent{$cluster, $environment} by {task_arn}.rollup(min)"
      aggregator = "avg"
      type       = "line"
    }
  }

  graph {
    title     = "Free Memory"
    viz       = "timeseries"
    autoscale = true

    request {
      q          = "avg:ecs.fargate.mem.usage{$cluster, $environment} by {task_arn}, avg:ecs.fargate.mem.limit{$cluster, $environment} by {task_arn}"
      aggregator = "avg"
      type       = "line"
    }
  }

  graph {
    title     = "Running Task Count"
    viz       = "timeseries"
    autoscale = true

    request {
      q          = "count_nonzero(avg:ecs.fargate.cpu.user{$cluster, $environment} by {task_arn})"
      aggregator = "avg"
      type       = "line"
    }
  }
}

module "monitor_cpu_usage" {
  source  = "github.com/traveloka/terraform-datadog-monitor"
  enabled = "${local.monitor_enabled}"

  product_domain = "${var.product_domain}"
  service        = "${var.service}"
  environment    = "${var.environment}"
  tags           = "${var.tags}"
  timeboard_id   = "${join(",", datadog_timeboard.system.*.id)}"

  name               = "${var.cpu_usage_name != "" ? 
                        "${var.cpu_usage_name}" : 
                        "${var.product_domain} - ${var.cluster} - ${var.environment} - CPU Usage is High on Task: {{ task_arn }}"}"
  query              = "avg:ecs.fargate.cpu.percent{cluster:${var.cluster}, environment:${var.environment}} by {task_arn} >= ${var.cpu_usage_thresholds["critical"]}"
  thresholds         = "${var.cpu_usage_thresholds}"
  message            = "${var.cpu_usage_message}"
  escalation_message = "${var.cpu_usage_escalation_message}"

  recipients         = "${var.recipients}"
  alert_recipients   = "${var.alert_recipients}"
  warning_recipients = "${var.warning_recipients}"

  renotify_interval = "${var.renotify_interval}"
  notify_audit      = "${var.notify_audit}"
  include_tags      = "${var.cpu_usage_include_tags}"
}

