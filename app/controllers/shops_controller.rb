# frozen_string_literal: true

class ShopsController < BaseController
  layout 'darkswarm'

  before_action :enable_embedded_shopfront

  def index
    @enterprises = ShopsListService.new.open_shops
  end
end
