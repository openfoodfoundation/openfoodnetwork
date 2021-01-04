# frozen_string_literal: true

module PaginationData
  extend ActiveSupport::Concern

  def pagination_data(objects, default_page: nil, default_per_page: nil)
    {
      results: objects.total_count,
      pages: objects.num_pages,
      page: (params[:page] || default_page).to_i,
      per_page: (params[:per_page] || default_per_page).to_i
    }
  end

  def pagination_required?
    params[:page].present? || params[:per_page].present?
  end
end
