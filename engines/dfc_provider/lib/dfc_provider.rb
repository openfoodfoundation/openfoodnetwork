# frozen_string_literal: true

# Load the DFC Connector:
require "datafoodconsortium/connector"

# Our Rails engine
require "dfc_provider/engine"

# Custom data types
require "dfc_provider/supplied_product"
require "dfc_provider/address"

module DfcProvider
  DataFoodConsortium::Connector::Importer.register_type(SuppliedProduct)
end
