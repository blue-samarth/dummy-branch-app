variable "github_token" {
  description = "GitHub token with repo and admin:repo_hook permissions"
  type        = string
  sensitive   = true
}
variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
  sensitive   = true
}
variable "dockerhub_token" {
  description = "Docker Hub token"
  type        = string
  sensitive   = true
}
variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  sensitive   = true
}
variable "postgres_password" {
    description = "PostgreSQL password"
    type        = string
    sensitive   = true
}
variable "postgres_db" {
    description = "PostgreSQL database name"
    type        = string
    sensitive   = true
}
variable "db_volume_path" {
    description = "Path for database volume"
    type        = string
}
