# frozen_string_literal: true

# Pagy Variables
# See https://ddnexus.github.io/pagy/api/pagy#variables
Pagy::VARS[:items]  = 100

# Items extra: Allow the client to request a custom number of items per page with an optional selector UI
# See https://ddnexus.github.io/pagy/extras/items
require 'pagy/extras/items'
Pagy::VARS[:items_param] = :per_page
Pagy::VARS[:max_items]   = 100
