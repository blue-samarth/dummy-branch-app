locals {
    environments = ["DEVELOPMENT", "STAGING", "PRODUCTION"]
}

provider "github" {
  token = var.github_token
}

resource "github_actions_secret" "docker_password" {
  repository      = "dummy-branch-app"
  secret_name     = "DOCKER_PASSWORD"
  plaintext_value = var.dockerhub_token
}

resource "github_actions_secret" "docker_username" {
  repository      = "dummy-branch-app"
  secret_name     = "DOCKER_USERNAME"
  plaintext_value = var.dockerhub_username
}

resource "github_actions_secret" "postgres_user" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  secret_name     = "POSTGRES_USER_${each.value}"
  plaintext_value = var.postgres_user
}

resource "github_actions_secret" "postgres_password" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  secret_name     = "POSTGRES_PASSWORD_${each.value}"
  plaintext_value = var.postgres_password
}

resource "github_actions_secret" "postgres_db" {
  for_each = toset(local.environments)
  repository      = "dummy-branch-app"
  secret_name     = "POSTGRES_DB_${each.value}"
  plaintext_value = var.postgres_db
}