# frozen_string_literal: true

# Load the DFC Connector:
require "datafoodconsortium/connector"
require "datafoodconsortium/connector_v1"

# Our Rails engine
require "dfc_provider/engine"

# Custom data types
require "dfc_provider/supplied_product"
require "dfc_provider/address"
require "dfc_provider/catalog_item"
require "dfc_provider/container"
require "dfc_provider/coordination"
require "dfc_provider/enterprise"

# 🙈 Monkey-patch a better inspector for semantic objects
require "semantic_object_inspect"

module DfcProvider
  DataFoodConsortium::ConnectorV1::Importer.register_type(Enterprise)
  DataFoodConsortium::ConnectorV1::Importer.register_type(SuppliedProduct)
end
