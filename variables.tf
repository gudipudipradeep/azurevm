variable "azure_region" {
  type = string
  description = "Azure region for deploying new resources"
  default = "westus"
}

variable "linux_flavors" {
  type = string
  description = "Name of the linux flavors"
  default = "UbuntuServer"
}

variable "linux_flavors_sku" {
  type = string
  description = "Name of the linux flavors sku"
  default = "18.04-LTS"
}

variable "size" {
  type = string
  description = "VM Size"
  default = "Standard_DS1_v2"
}

variable "no_vm" {
  type = number
  description = "No VM"
  default = 2
}

variable "type_of_db" {
  type = string
  description = "Cosmosdb"
  default = "EnableMongo"
}

variable "failover_location" {
  type = string
  description = "failover location cosmosdb"
  default = "westus"
}

variable "user_name_databricks_access" {
  type = string
  description = "failover location cosmosdb"
  default = "sobhithaa9@gmail.com"
}
