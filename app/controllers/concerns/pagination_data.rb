# frozen_string_literal: true

module PaginationData
  extend ActiveSupport::Concern

  def pagination_data(objects)
    return unless objects.respond_to? :total_count

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

  def default_per_page
    return unless defined? self.class::DEFAULT_PER_PAGE

    self.class::DEFAULT_PER_PAGE
  end
end
