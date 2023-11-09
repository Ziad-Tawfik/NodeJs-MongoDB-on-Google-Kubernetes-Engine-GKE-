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

variable "sa_acc_id" {
  type = list(string)
}

variable "sa_acc_desc" {
  type = list(string)
}

variable "subnet_names" {
  type = list(string)
}

variable "subnet_regions" {
  type = list(string)
}

variable "management_vm_zone" {
  type = string
}

variable "cidrs" {
  type = list(string)
}

variable "management_roles" {
  type = list(string)
}

variable "workload_roles" {
  type = list(string)
}

variable "artifact_repo_id" {
  type = string
}