# frozen_string_literal: true

module JsonApiPagination
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 50
  MAX_PER_PAGE = 200

  def pagination_options
    {
      is_collection: true,
      meta: meta_options,
      links: links_options,
    }
  end

  def pagy_options
    # Pagy resolves a missing/out-of-range :page itself when we don't pass one, silently
    # clamping it to 1 instead of raising. Passing our own parsed value makes pagy validate
    # it via Pagy::Offset#assign_and_check instead (raising Pagy::OptionError on eg. page=0),
    # preserving the v1 API's existing "informs about invalid pages" contract.
    { items: final_per_page_value, page: current_page }
  end

  private

  def meta_options
    {
      pagination: {
        results: @pagy.count,
        pages: total_pages,
        page: current_page,
        per_page: final_per_page_value
      }
    }
  end

  def links_options
    {
      self: pagination_url(current_page),
      first: pagination_url(1),
      prev: pagination_url(previous_page),
      next: pagination_url(next_page),
      last: pagination_url(total_pages)
    }
  end

  def pagination_url(page_number)
    return if page_number.nil?

    url_for(only_path: false, params: request.query_parameters.merge(page: page_number))
  end

  # User-specified value, or DEFAULT_PER_PAGE, capped at MAX_PER_PAGE
  def final_per_page_value
    (params[:per_page] || DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
  end

  def current_page
    (params[:page] || 1).to_i
  end

  def total_pages
    @pagy.pages
  end

  def previous_page
    return nil if current_page < 2

    current_page - 1
  end

  def next_page
    return nil if current_page >= total_pages

    current_page + 1
  end
end
