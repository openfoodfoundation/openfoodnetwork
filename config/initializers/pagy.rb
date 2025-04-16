# frozen_string_literal: true

require 'pagy/extras/arel'
require 'pagy/extras/array'
require 'pagy/extras/limit'
require 'pagy/extras/overflow'
require 'pagy/extras/size'

# Pagy Variables
# See https://ddnexus.github.io/pagy/api/pagy#variables
Pagy::DEFAULT[:limit] = 100

# limit extra: Allow the client to request a custom number of limit per page with an optional
# selector UI
# See https://ddnexus.github.io/pagy/extras/limit
Pagy::DEFAULT[:limit_param] = :per_page
Pagy::DEFAULT[:limit_max]   = 100

# For handling requests for non-existant pages eg: page 35 when there are only 4 pages of results
Pagy::DEFAULT[:overflow] = :empty_page
