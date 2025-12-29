# frozen_string_literal: true

module Reports
  module AjaxSearch
    extend ActiveSupport::Concern

    def search_enterprise_fees
      report = report_class.new(spree_current_user, params, render: false)
      fee_ids = enterprise_fee_ids(report.search.result)
      query = EnterpriseFee.where(id: fee_ids)

      render json: build_search_response(query)
    end

    def search_enterprise_fee_owners
      report = report_class.new(spree_current_user, params, render: false)
      owner_ids = enterprise_fee_owner_ids(report.search.result)
      query = Enterprise.where(id: owner_ids)

      render json: build_search_response(query)
    end

    def search_distributors
      query = frontend_data.distributors

      render json: build_search_response(query)
    end

    def search_order_cycles
      query = frontend_data.order_cycles

      render json: build_search_response(query)
    end

    def search_order_customers
      query = frontend_data.order_customers

      render json: build_search_response(query)
    end

    def search_suppliers
      query = frontend_data.orders_suppliers

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

      # Handle different model types
      if query.model == OrderCycle
        query.where("order_cycles.name ILIKE ?", "%#{search_term}%")
      elsif query.model == Customer
        query.where("customers.email ILIKE ?", "%#{search_term}%")
      else
        query.where("name ILIKE ?", "%#{search_term}%")
      end
    end

    def paginated_items(query, page, per_page)
      if query.model == Customer
        query.order(:email).offset((page - 1) * per_page).limit(per_page).pluck(:email, :id)
      elsif query.model == OrderCycle
        query.order('order_cycles.orders_close_at DESC')
          .offset((page - 1) * per_page)
          .limit(per_page).pluck(
            :name, :id
          )
      else
        query.order(:name).offset((page - 1) * per_page).limit(per_page).pluck(:name, :id)
      end
    end

    def format_results(items)
      items.map { |name, id| { id: id, text: name } }
    end

    def frontend_data
      @frontend_data ||= Reporting::FrontendData.new(spree_current_user)
    end

    def enterprise_fee_owner_ids(orders)
      EnterpriseFee.where(id: enterprise_fee_ids(orders)).select(:enterprise_id)
    end

    def enterprise_fee_ids(orders)
      Spree::Adjustment.enterprise_fee.where(order_id: orders.select(:id)).select(:originator_id)
    end
  end
end
