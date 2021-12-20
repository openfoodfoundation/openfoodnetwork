# frozen_string_literal: true

module JsonApiPagination
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 50
  MAX_PER_PAGE = 200

  def pagination_options
    current_page = params[:page] || 1
    total_pages = @pagy.pages
    previous_page = current_page > 1 ? (current_page - 1) : nil
    next_page = current_page < total_pages ? (current_page + 1) : nil

    {
      is_collection: true,
      meta: {
        pagination: {
          results: @pagy.count,
          pages: total_pages,
          page: current_page,
          per_page: final_per_page_value
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
    { items: final_per_page_value }
  end

  private

  def pagination_url(page_number)
    return if page_number.nil?

    url_for(only_path: false, params: request.query_parameters.merge(page: page_number))
  end

  # User-specified value, or DEFAULT_PER_PAGE, capped at MAX_PER_PAGE
  def final_per_page_value
    (params[:per_page] || DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
  end
end
