# frozen_string_literal: true

# Load the DFC Connector:
require "datafoodconsortium/connector"

# Our Rails engine
require "dfc_provider/engine"

# Custom data types
require "dfc_provider/supplied_product"
require "dfc_provider/address"
require "dfc_provider/catalog_item"
require "dfc_provider/coordination"

# 🙈 Monkey-patch a better inspector for semantic objects
require "semantic_object_inspect"

module DfcProvider
  DataFoodConsortium::Connector::Importer.register_type(SuppliedProduct)
end
