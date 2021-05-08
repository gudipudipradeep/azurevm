resource "azurerm_resource_group" "rscosmosdb" {
    name     = "RSCosmosdb"
    location = "${var.azure_region}"

    tags = {
        environment = "Cosmosdb Creation"
    }
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "acc" {
  name                = "cosmos-db-${random_integer.ri.result}"
  location            = "${var.azure_region}"
  resource_group_name = azurerm_resource_group.rscosmosdb.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  depends_on = ["azurerm_subnet.AZsubnet"]

  enable_automatic_failover = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }
  
  geo_location {
    location          = var.failover_location
    failover_priority = 0
  }
  
  is_virtual_network_filter_enabled = true
  public_network_access_enabled     = true
  virtual_network_rule {
    id = azurerm_subnet.AZsubnet.id
    ignore_missing_vnet_service_endpoint = true

  }
}


resource "azurerm_cosmosdb_table" "db" {
  name = "cosmosd_table"
  count               = "${var.type_of_db == "EnableTable" ? 1 : 0}"
  resource_group_name = "${azurerm_cosmosdb_account.acc.resource_group_name}"
  account_name = "${azurerm_cosmosdb_account.acc.name}"
  throughput          = 400
}

resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  name                = "cosmosmongodb"
  count               = "${var.type_of_db == "EnableMongo" ? 1 : 0}"
  resource_group_name = "${azurerm_cosmosdb_account.acc.resource_group_name}"
  account_name = "${azurerm_cosmosdb_account.acc.name}"
  throughput          = 400
}

resource "azurerm_cosmosdb_gremlin_database" "gremlin" {
  name                = "gremlin_database"
  count               = "${var.type_of_db == "EnableGremlin" ? 1 : 0}"
  resource_group_name = "${azurerm_cosmosdb_account.acc.resource_group_name}"
  account_name = "${azurerm_cosmosdb_account.acc.name}"
  throughput          = 400
}

