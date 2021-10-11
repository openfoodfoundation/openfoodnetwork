# frozen_string_literal: true

module JsonApiPagination
  extend ActiveSupport::Concern

  def pagination_options
    current_page = params[:page] || 1
    total_pages = @pagy.pages
    previous_page = (current_page > 1) ? (current_page - 1) : nil
    next_page = (current_page < total_pages) ? (current_page + 1) : nil

    {
      is_collection: true,
      meta: {
        pagination: {
          results: @pagy.count,
          pages: total_pages,
          page: current_page,
          per_page: (params[:per_page] || self.class::RESULTS_PER_PAGE)
        }
      },
      links: {
        self: pagination_url(current_page),
        first: pagination_url(1),
        prev: pagination_url(previous_page),
        next: pagination_url(next_page),
        last: pagination_url(total_pages)
      }
    }
  end

  def pagy_options
    { items: params[:per_page] || self.class::RESULTS_PER_PAGE }
  end

  private

  def pagination_url(page_number)
    return if page_number.nil?

    url_for(only_path: false, params: request.query_parameters.merge(page: page_number))
  end
end
