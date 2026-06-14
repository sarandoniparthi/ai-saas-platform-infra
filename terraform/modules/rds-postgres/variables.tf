variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to PostgreSQL."
  type        = map(string)
}

variable "database_name" {
  type    = string
  default = "appdb"
}

variable "database_username" {
  type    = string
  default = "app_admin"
}

variable "database_password" {
  description = "Initial PostgreSQL password. Use a secret value from tfvars or CI secret storage."
  type        = string
  sensitive   = true
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}
