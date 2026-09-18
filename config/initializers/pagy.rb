# frozen_string_literal: true

# Pagy Variables
# See https://ddnexus.github.io/pagy/toolbox/configuration/options/
Pagy::OPTIONS[:limit] = 100

# Allow the client to request a custom number of items per page with ?per_page=N, capped at
# :max_limit. :max_limit also acts as the switch that makes pagy read the client param at all.
Pagy::OPTIONS[:limit_key] = 'per_page'
Pagy::OPTIONS[:max_limit] = 100

# Handling requests for non-existant pages (eg: page 35 when there are only 4 pages of results)
# by returning an empty page is the default behaviour in v43, so nothing to configure here.

Pagy::OPTIONS.freeze

# v43 made #series and #a_lambda protected (its own nav helpers, e.g. #series_nav, call them
# internally). OFN renders its own pagination markup (Stimulus-driven links, custom classes)
# in app/views/admin/shared/_pagy_links.html.haml and _stimulus_pagination.html.haml instead
# of using #series_nav, so those views need public access to the page series and the anchor
# builder. Don't try `public :series` here instead: #series and #a_lambda are lazily loaded on
# first call (see pagy/toolbox/helpers/loaders.rb), and that load redefines them as protected,
# clobbering any visibility change made ahead of time.
class Pagy
  def page_series(**) = series(**)
  def page_anchor(**) = a_lambda(**)
end
