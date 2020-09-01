output "timeboard_title" {
  value       = "${join(",", datadog_timeboard.system.*.title)}"
  description = "The title of datadog timeboard for System"
}

output "monitor_cpu_usage_name" {
  value       = "${module.monitor_cpu_usage.name}"
  description = "The name of datadog monitor for CPU Usage"
}