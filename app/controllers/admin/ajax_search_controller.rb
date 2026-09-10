# frozen_string_literal: true

module Admin
  class AjaxSearchController < Spree::Admin::BaseController
    def producers
      query = OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_product_enterprises_and_enterprises_granting_linked_variants
        .is_primary_producer
        .by_name

      render json: build_search_response(query)
    end

    def categories
      render json: build_taxon_search_response
    end

    def tax_categories
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

    def build_taxon_search_response
      page = (params[:page] || 1).to_i
      per_page = 30

      # Taxon#name is locale-aware (resolved from name_i18n in Ruby), so it can't be
      # sorted/paginated in SQL via order/limit like the other search endpoints.
      # We filter in SQL when possible (to avoid instantiating all records for a search)
      # then sort and paginate in Ruby.
      taxons = filter_taxons_sql.to_a
      taxons = taxons.sort_by(&:name)
      total_count = taxons.size
      items = taxons.slice((page - 1) * per_page, per_page) || []

      results = items.map { |t| { value: t.id, label: t.name } }
      { results: results, pagination: { more: (page * per_page) < total_count } }
    end

    def filter_taxons_sql
      search_term = params[:q]
      return Spree::Taxon.all if search_term.blank?

      escaped = ActiveRecord::Base.sanitize_sql_like(search_term)
      # Casting jsonb to text searches across all locale keys and values.
      # A GIN index on name_i18n helps PostgreSQL skip rows that can't match.
      Spree::Taxon.where("name_i18n::text ILIKE ?", "%#{escaped}%")
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
