output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}

output "vm_password" {
  value = "${random_password.admin_password.result}"
}

output "ip_of_vm" {
  value = "${azurerm_public_ip.VMPublicIIP}"
}

output "cosmosdb_key" {
  value = "${azurerm_cosmosdb_account.acc.primary_key}"
}

output "cosmosdb_connection_string" {
  value = "${azurerm_cosmosdb_account.acc.connection_strings}"
}
