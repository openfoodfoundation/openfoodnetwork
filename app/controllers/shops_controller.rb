# frozen_string_literal: true

class ShopsController < BaseController
  include EmbeddedPages

  layout 'darkswarm'

  def index
    @enterprises = ShopsListService.new.open_shops
  end
end
