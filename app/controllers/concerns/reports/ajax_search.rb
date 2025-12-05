# frozen_string_literal: true

module Reports
  module AjaxSearch
    extend ActiveSupport::Concern

    def search_enterprise_fees
      cached_response = cached_search_response('enterprise_fees') do
        report = report_class.new(spree_current_user, params, render: false)
        fee_ids = enterprise_fee_ids(report.search.result)
        EnterpriseFee.where(id: fee_ids)
      end

      render json: cached_response
    end

    def search_enterprise_fee_owners
      cached_response = cached_search_response('enterprise_fee_owners') do
        report = report_class.new(spree_current_user, params, render: false)
        owner_ids = enterprise_fee_owner_ids(report.search.result)
        Enterprise.where(id: owner_ids)
      end

      render json: cached_response
    end

    private

    def cached_search_response(resource_type)
      cache_key = build_cache_key(resource_type)
      CacheService.cache(cache_key, expires_in: 5.minutes) do
        query = yield
        build_search_response(query)
      end
    end

    def build_cache_key(resource_type)
      key_params = [
        'reports',
        params[:report_type],
        params[:report_subtype],
        resource_type,
        'search',
        spree_current_user.id,
        params[:q],
        params[:page]
      ]
      key_params.join('_')
    end

    def build_search_response(query)
      page = (params[:page] || 1).to_i
      per_page = 30

      filtered_query = apply_search_filter(query)
      total_count = filtered_query.count
      items = paginated_items(filtered_query, page, per_page)
      results = format_results(items)

      { results: results, pagination: { more: (page * per_page) < total_count } }
    end

    def apply_search_filter(query)
      search_term = params[:q]
      return query if search_term.blank?

      query.where("name ILIKE ?", "%#{search_term}%")
    end

    def paginated_items(query, page, per_page)
      query.order(:name).offset((page - 1) * per_page).limit(per_page).pluck(:name, :id)
    end

    def format_results(items)
      items.map { |name, id| { id: id, text: name } }
    end

    def enterprise_fee_owner_ids(orders)
      EnterpriseFee.where(id: enterprise_fee_ids(orders)).select(:enterprise_id)
    end

    def enterprise_fee_ids(orders)
      Spree::Adjustment.enterprise_fee.where(order_id: orders.select(&:id)).select(:originator_id)
    end
  end
end
