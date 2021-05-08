terraform {
  required_providers {
    databricks = {
      source = "databrickslabs/databricks"
      version = "0.3.2"
    }
  }
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "databrick_workspace"
  resource_group_name         = azurerm_resource_group.rsgroup.name
  location                    = "${var.azure_region}"
  depends_on                  = ["azurerm_subnet.AZsubnet"]
  sku                         = "premium"
  custom_parameters {
    virtual_network_id  = azurerm_virtual_network.AZVnet.id
    public_subnet_name  = "databrickpublicsubnet"
    private_subnet_name = "databrickprivatesubnet"
  }
}


provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.this.id
}

resource "databricks_cluster" "shared_autoscaling" {
    cluster_name            = "Shared Autoscaling"
    node_type_id            = "Standard_DS3_v2"
    spark_version           = "6.6.x-scala2.11"
    autotermination_minutes = 20
    
    autoscale {
        min_workers = 1
        max_workers = 1000
    }
    
  azure_attributes {
    availability       = "SPOT_AZURE"
    spot_bid_max_price = 100
  }
}   

resource "databricks_user" "user_access" {
    user_name = "${var.user_name_databricks_access}"
}

resource "databricks_group" "databricks_access" {
    display_name = "databricks_acc_manage"
}

resource "databricks_permissions" "cluster_usage" {
    cluster_id = databricks_cluster.shared_autoscaling.cluster_id
    access_control {
        group_name = databricks_group.databricks_access.display_name
        permission_level = "CAN_MANAGE"
    }
}

resource "databricks_group_member" "grouop_user_mapping" {
    group_id = databricks_group.databricks_access.id
    member_id = databricks_user.user_access.id
}

