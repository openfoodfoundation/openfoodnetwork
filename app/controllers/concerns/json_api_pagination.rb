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
    {
      # :limit is the number of records pagy actually returns. max_limit overrides, for this
      # call only, the app-wide Pagy::OPTIONS[:max_limit] that every other paginated endpoint
      # shares - without it, a per_page above that app-wide cap would be silently trimmed
      # below MAX_PER_PAGE, disagreeing with the per_page reported in meta.pagination/links.
      limit: final_per_page_value,
      max_limit: MAX_PER_PAGE,
      # Pagy resolves a missing/out-of-range :page itself when we don't pass one, silently
      # clamping it to 1 instead of raising. Passing our own parsed value makes pagy validate
      # it via Pagy::Offset#assign_and_check instead (raising Pagy::OptionError on eg. page=0),
      # preserving the v1 API's existing "informs about invalid pages" contract.
      page: current_page,
      # JSON:API-shaped pagination params/links (page[number]/page[per_page]), scoped to this
      # call only - Pagy::OPTIONS is shared by every other paginated endpoint (admin views,
      # ProductsRenderer, the v0 API), none of which are JSON:API responses.
      jsonapi: true,
      page_key: 'number',
      limit_key: 'per_page',
      # Pagy::OffsetPaginator always calls Pagy::Request#resolve_limit itself, even though we
      # already pass :limit above - and resolve_limit does params.dig('page', 'per_page'). A
      # pre-existing flat ?page=/?per_page= request leaves params['page'] as a String, and
      # String has no #dig, so the request blows up. Building our own :request hash strips
      # those two legacy keys, but only when 'page' isn't already the nested Hash a proper
      # page[number]/page[per_page] request produces (current_page/final_per_page_value above
      # read the parsed params directly either way).
      request: pagy_request,
    }
  end

  private

  def pagy_request
    {
      base_url: request.base_url,
      path: request.path,
      # request.GET/.POST are HashWithIndifferentAccess: assigning a plain Hash into one of its
      # keys wraps it in a new HashWithIndifferentAccess rather than storing it as-is, so pagy's
      # in-place mutation of the page[] container it just wrote there is silently lost. #to_h
      # converts to a plain Hash first, same as Pagy::Request's own default request handling.
      params: pagy_request_params,
      cookie: request.cookies['pagy'],
    }
  end

  def pagy_request_params
    raw = request.GET.merge(request.POST).to_h

    return raw if raw['page'].is_a?(Hash)

    raw.except('page', 'per_page')
  end

  def meta_options
    {
      pagination: {
        results: @pagy.count,
        pages: @pagy.pages,
        page: @pagy.page,
        per_page: @pagy.limit
      }
    }
  end

  def links_options
    urls = @pagy.urls_hash(absolute: true)

    {
      self: @pagy.data_hash(data_keys: [:current_url], absolute: true)[:current_url],
      first: urls[:first],
      prev: urls[:previous],
      next: urls[:next],
      last: urls[:last]
    }
  end

  # User-specified value, or DEFAULT_PER_PAGE, capped at MAX_PER_PAGE
  def final_per_page_value
    (page_param[:per_page] || DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
  end

  def current_page
    (page_param[:number] || 1).to_i
  end

  # JSON:API-shaped page[number]/page[per_page] params. A pre-existing flat ?page=/?per_page=
  # isn't a Hash, so it's treated the same as no page param at all rather than raising.
  def page_param
    params[:page].is_a?(ActionController::Parameters) ? params[:page] : {}
  end
end
