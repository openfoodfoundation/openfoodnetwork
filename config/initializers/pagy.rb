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

# v43's Pagy::Request builds the params for pagination links from GET *and* POST (pagy 9 used
# GET only). Admin::EnterprisesController#bulk_update re-renders the index from a PUT when the
# set fails to save, which would embed the whole submitted form - every enterprise row, plus
# authenticity_token and _method - in every page link. Only the query string belongs in a link.
#
# Pagy::Request isn't autoloaded (only Pagy::Method is, and it require_relative's this), so the
# require is needed. Prepending rather than reopening keeps that honest: without the require,
# Pagy::Request.prepend raises NameError at boot instead of quietly defining a fresh class that
# pagy's own request.rb then overwrites.
require 'pagy/classes/request'

module PagyRequestQueryParamsOnly
  private

  def get_params(request) = request.GET.to_h.freeze
end

Pagy::Request.prepend PagyRequestQueryParamsOnly

require 'pagy/toolbox/helpers/support/series'

module SeriesOverride
  protected
  # The array of page numbers and :gap e.g. [1, :gap, 8, "9", 10, :gap, 36]
  # extra options:
  #  - max_slots: max number of slots, default 7
  #
  def series(slots: @options[:slots] || Pagy::SERIES_SLOTS, compact: @options[:compact], **options)
    raise OptionError.new(self, :slots, 'to be an Integer >= 0', slots) unless slots.is_a?(Integer) && slots >= 0
    max_slots = options[:max_slots] || Pagy::SERIES_SLOTS
    return [] if slots.zero?

    [].tap do |series|
      if slots >= @last
        series.push(*1..@last)
      else
        half  = (slots - 1) / 2                       # even slots makes the left half shorter by 1
        start = if @page <= half                      # @page in the first half
                  1
                elsif @page > (@last - slots + half)  # @page in the last half
                  @last - slots + 1
                else                                  # @page in the middle
                  @page - half
                end
        series.push(*(start...(start + slots)))
        unless compact || slots < max_slots            # Set first, last and :gap when needed
          series[0]  = 1
          series[1]  = :gap unless series[1]  == 2
          series[-2] = :gap unless series[-2] == @last - 1
          series[-1] = @last
        end
      end
      current = series.index(@page)
      series[current] = @page.to_s if current
    end
  end
end

Pagy.prepend SeriesOverride
