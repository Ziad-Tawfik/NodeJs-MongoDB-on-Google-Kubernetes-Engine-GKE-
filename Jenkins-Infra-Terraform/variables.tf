variable "project" {
  type        = string
  description = "Your GCP Project ID"
}

variable "services" {
  type = list(string)
}

variable "dis_on_dest" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_region" {
  type = string
}

variable "jenkins_vm_zone" {
  type = string
}

variable "cidr" {
  type = string
}
