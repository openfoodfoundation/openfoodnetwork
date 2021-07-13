# frozen_string_literal: true

module PaginationData
  extend ActiveSupport::Concern

  def pagination_data
    return unless defined? @pagy

    {
      results: @pagy.count,
      pages: @pagy.pages,
      page: (params[:page] || 1).to_i,
      per_page: (params[:per_page] || default_per_page).to_i
    }
  end

  def pagination_required?
    params[:page].present? || params[:per_page].present?
  end

  def default_per_page
    return unless defined? self.class::DEFAULT_PER_PAGE

    self.class::DEFAULT_PER_PAGE
  end
end
