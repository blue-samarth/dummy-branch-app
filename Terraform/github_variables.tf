resource "github_actions_variable" "healthcheck_interval" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  variable_name   = "HEALTHCHECK_INTERVAL_${each.value}"
  value = "30s"
}

resource "github_actions_variable" "healthcheck_timeout" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  variable_name   = "HEALTHCHECK_TIMEOUT_${each.value}"
  value = "10s"
}

resource "github_actions_variable" "healthcheck_retries" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  variable_name   = "HEALTHCHECK_RETRIES_${each.value}"
  value = "5"
}

resource "github_actions_variable" "app_cpu_limit" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  variable_name   = "APP_CPU_LIMIT_${each.value}"
  value = "500m"
}

resource "github_actions_variable" "app_memory_limit" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  variable_name   = "APP_MEMORY_LIMIT_${each.value}"
  value = "512Mi"
}

resource "github_actions_variable" "db_cpu_limit" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  variable_name   = "DB_CPU_LIMIT_${each.value}"
  value = "500m"
}
resource "github_actions_variable" "db_memory_limit" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  variable_name   = "DB_MEMORY_LIMIT_${each.value}"
  value = "512Mi"
}

