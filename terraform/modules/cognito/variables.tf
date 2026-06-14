variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "callback_urls" {
  description = "Allowed OAuth callback URLs for the application."
  type        = list(string)
}

variable "logout_urls" {
  description = "Allowed OAuth logout URLs for the application."
  type        = list(string)
}

