# frozen_string_literal: true

class ProducersController < BaseController
  include EmbeddedPages

  layout 'darkswarm'

  def index
    @enterprises = Enterprise
      .activated
      .visible
      .is_primary_producer
      .includes(address: [:state, :country])
      .includes(:properties)
      .includes(supplied_products: :properties)
      .all
  end
end
