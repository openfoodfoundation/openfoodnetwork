# frozen_string_literal: true

module PaginationData
  extend ActiveSupport::Concern

  def pagination_data(objects)
    {
      results: objects.total_count,
      pages: objects.total_pages,
      page: (params[:page] || 1).to_i,
      per_page: (params[:per_page] || default_per_page).to_i
    }
  end

  def pagination_required?
    params[:page].present? || params[:per_page].present?
  end

  private

  def default_per_page
    return unless defined? DEFAULT_PER_PAGE

    DEFAULT_PER_PAGE
  end
end
