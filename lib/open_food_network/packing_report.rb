require "open_food_network/reports/line_items"

module OpenFoodNetwork
  class PackingReport
    attr_reader :params
    def initialize(user, params = {}, render_table = false)
      @params = params
      @user = user
      @render_table = render_table
    end

    def header
      if is_by_customer?
        [
          I18n.t(:report_header_hub),
          I18n.t(:report_header_code),
          I18n.t(:report_header_first_name),
          I18n.t(:report_header_last_name),
          I18n.t(:report_header_supplier),
          I18n.t(:report_header_product),
          I18n.t(:report_header_variant),
          I18n.t(:report_header_quantity),
          I18n.t(:report_header_temp_controlled),
        ]
      else
        [
          I18n.t(:report_header_hub),
          I18n.t(:report_header_supplier),
          I18n.t(:report_header_code),
          I18n.t(:report_header_first_name),
          I18n.t(:report_header_last_name),
          I18n.t(:report_header_product),
          I18n.t(:report_header_variant),
          I18n.t(:report_header_quantity),
          I18n.t(:report_header_temp_controlled),
        ]
      end
    end

    def search
      Reports::LineItems.search_orders(permissions, params)
    end

    def table_items
      return [] unless @render_table
      Reports::LineItems.list(permissions, params)
    end

    def rules
      if is_by_customer?
        [
          { group_by: proc { |line_item| line_item.order.distributor },
          sort_by: proc { |distributor| distributor.name } },
          { group_by: proc { |line_item| line_item.order },
          sort_by: proc { |order| order.bill_address.lastname },
          summary_columns: [ proc { |line_items| "" },
            proc { |line_items| "" },
            proc { |line_items| "" },
            proc { |line_items| "" },
            proc { |line_items| "" },
            proc { |line_items| I18n.t('admin.reports.total_items') },
            proc { |line_items| "" },
            proc { |line_items| line_items.sum { |li| li.quantity } },
            proc { |line_items| "" } ] },
          { group_by: proc { |line_item| line_item.product.supplier },
            sort_by: proc { |supplier| supplier.name } },
          { group_by: proc { |line_item| line_item.product },
          sort_by: proc { |product| product.name } },
          { group_by: proc { |line_item| line_item.full_name },
            sort_by: proc { |full_name| full_name } }
        ]
      else
        [ { group_by: proc { |line_item| line_item.order.distributor },
          sort_by: proc { |distributor| distributor.name } },
          { group_by: proc { |line_item| line_item.product.supplier },
            sort_by: proc { |supplier| supplier.name },
            summary_columns: [ proc { |line_items| "" },
              proc { |line_items| "" },
              proc { |line_items| "" },
              proc { |line_items| "" },
              proc { |line_items| "" },
              proc { |line_items| I18n.t('admin.reports.total_items') },
              proc { |line_items| "" },
              proc { |line_items| line_items.sum { |li| li.quantity } },
              proc { |line_items| "" } ] },
          { group_by: proc { |line_item| line_item.product },
          sort_by: proc { |product| product.name } },
          { group_by: proc { |line_item| line_item.full_name },
          sort_by: proc { |full_name| full_name } },
          { group_by: proc { |line_item| line_item.order },
          sort_by: proc { |order| order.bill_address.lastname } } ]
      end
    end

    def columns
      if is_by_customer?
        [ proc { |line_items| line_items.first.order.distributor.name },
          proc { |line_items| customer_code(line_items.first.order.email) },
          proc { |line_items| line_items.first.order.bill_address.firstname },
          proc { |line_items| line_items.first.order.bill_address.lastname },
          proc { |line_items| line_items.first.product.supplier.name },
          proc { |line_items| line_items.first.product.name },
          proc { |line_items| line_items.first.full_name },
          proc { |line_items| line_items.sum { |li| li.quantity } },
          proc { |line_items| is_temperature_controlled?(line_items.first) }]
      else
        [
          proc { |line_items| line_items.first.order.distributor.name },
          proc { |line_items| line_items.first.product.supplier.name },
          proc { |line_items| customer_code(line_items.first.order.email) },
          proc { |line_items| line_items.first.order.bill_address.firstname },
          proc { |line_items| line_items.first.order.bill_address.lastname },
          proc { |line_items| line_items.first.product.name },
          proc { |line_items| line_items.first.full_name },
          proc { |line_items| line_items.sum { |li| li.quantity } },
          proc { |line_items| is_temperature_controlled?(line_items.first) }
        ]
      end
    end

    private

    def permissions
      return @permissions unless @permissions.nil?
      @permissions = OpenFoodNetwork::Permissions.new(@user)
    end

    def is_temperature_controlled?(line_item)
      if line_item.product.shipping_category.andand.temperature_controlled
        "Yes"
      else
        "No"
      end
    end

    def is_by_customer?
      params[:report_type] == "pack_by_customer"
    end

    def customer_code(email)
      customer = Customer.where(email: email).first
      customer.nil? ? "" : customer.code
    end
  end
end
