# frozen_string_literal: true

# Load our monkey-patches of the DFC Connector:
require "data_food_consortium/connector/connector"

# Our Rails engine
require "dfc_provider/engine"

# Custom data types
require "dfc_provider/supplied_product"

module DfcProvider
end
