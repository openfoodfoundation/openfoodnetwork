# frozen_string_literal: true

module Products
  module AjaxSearch
    extend ActiveSupport::Concern

    def search_producers
      query = OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises.is_primary_producer.by_name

      render json: build_search_response(query)
    end

    def search_categories
      query = Spree::Taxon.all

      render json: build_search_response(query)
    end

    def search_tax_categories
      query = Spree::TaxCategory.all

      render json: build_search_response(query)
    end

    private

    def build_search_response(query)
      page = (params[:page] || 1).to_i
      per_page = 30

      filtered_query = apply_search_filter(query)
      total_count = filtered_query.size
      items = paginated_items(filtered_query, page, per_page)
      results = format_results(items)

      { results: results, pagination: { more: (page * per_page) < total_count } }
    end

    def apply_search_filter(query)
      search_term = params[:q]
      return query if search_term.blank?

      escaped_search_term = ActiveRecord::Base.sanitize_sql_like(search_term)
      pattern = "%#{escaped_search_term}%"

      query.where('name ILIKE ?', pattern)
    end

    def paginated_items(query, page, per_page)
      query.order(:name).offset((page - 1) * per_page).limit(per_page).pluck(:name, :id)
    end

    def format_results(items)
      items.map { |label, value| { value:, label: } }
    end
  end
end
