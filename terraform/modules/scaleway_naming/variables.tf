variable environment {
  description = "The environment for which the resources are being created (DEV or PRD)"
  type        = string
  nullable = false
  validation {
    condition = lower(var.environment) == "dev" || lower(var.environment) == "prod"
    error_message = "Only supports 'dev' or 'prod'" 
  }
}

variable resource_type {
  description = "The type of resource being created (e.g., ObjectStorage, ContainerRegistry, CPUInstance, VPC, LoadBalancer)"
  type        = string
  nullable = false
  validation {
    condition = contains(local.resources_supported, var.resource_type)
    error_message = "Only supports the following resource types: ${join(", ", local.resources_supported)}"
  }
}

variable product_name {
  description = "The name of the product for which the resources are being created. Can not be longer than 20 characters."
  type        = string
  nullable = false
  validation {
    condition = length(var.product_name) > 0 && length(var.product_name) <= 20
    error_message = "Product name cannot be empty and must be 20 characters or less"
  }
}

variable region {
  description = "The region where the resources will be created (e.g., fr-par, nl-ams, pl-waw)"
  type        = string
  nullable = false
  validation {
    condition = var.region == "fr-par" || var.region == "nl-ams" || var.region == "pl-waw"
    error_message = "Region must be one of the following: fr-par, nl-ams, pl-waw"
  }
}