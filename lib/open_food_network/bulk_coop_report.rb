require 'open_food_network/reports/bulk_coop_supplier_report'
require 'open_food_network/reports/bulk_coop_allocation_report'

module OpenFoodNetwork
  class BulkCoopReport
    attr_reader :params
    def initialize(user, params = {})
      @params = params
      @user = user

      @supplier_report = OpenFoodNetwork::Reports::BulkCoopSupplierReport.new
      @allocation_report = OpenFoodNetwork::Reports::BulkCoopAllocationReport.new
    end

    def header
      case params[:report_type]
      when "bulk_coop_supplier_report"
        @supplier_report.header
      when "bulk_coop_allocation"
        @allocation_report.header
      when "bulk_coop_packing_sheets"
        [I18n.t(:report_header_customer),
          I18n.t(:report_header_product),
          I18n.t(:report_header_variant),
          I18n.t(:report_header_sum_total)]
      when "bulk_coop_customer_payments"
        [I18n.t(:report_header_customer),
          I18n.t(:report_header_date_of_order),
          I18n.t(:report_header_total_cost),
          I18n.t(:report_header_amount_owing),
          I18n.t(:report_header_amount_paid)]
      else
        [I18n.t(:report_header_supplier),
          I18n.t(:report_header_product),
          I18n.t(:report_header_product),
          I18n.t(:report_header_bulk_unit_size),
          I18n.t(:report_header_variant),
          I18n.t(:report_header_weight),
          I18n.t(:report_header_sum_total),
          I18n.t(:report_header_sum_max_total),
          I18n.t(:report_header_units_required),
          I18n.t(:report_header_remainder)]
      end
    end

    def search
      permissions.visible_orders.complete.not_state(:canceled).search(params[:q])
    end

    def table_items
      orders = search.result

      line_items = permissions.visible_line_items.merge(Spree::LineItem.where(order_id: orders))

      line_items_with_hidden_details =
        permissions.editable_line_items.empty? ? line_items : line_items.where('"spree_line_items"."id" NOT IN (?)', permissions.editable_line_items)

      line_items.select{ |li| line_items_with_hidden_details.include? li }.each do |line_item|
        # TODO We should really be hiding customer code here too, but until we
        # have an actual association between order and customer, it's a bit tricky
        line_item.order.bill_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        line_item.order.ship_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        line_item.order.assign_attributes(email: I18n.t('admin.reports.hidden'))
      end
      line_items
    end

    def rules
      case params[:report_type]
      when "bulk_coop_supplier_report"
        @supplier_report.rules
      when "bulk_coop_allocation"
        @allocation_report.rules
      when "bulk_coop_packing_sheets"
        [ { group_by: proc { |li| li.product },
          sort_by: proc { |product| product.name } },
          { group_by: proc { |li| li.full_name },
          sort_by: proc { |full_name| full_name } },
          { group_by: proc { |li| li.order },
          sort_by: proc { |order| order.to_s } } ]
      when "bulk_coop_customer_payments"
        [ { group_by: proc { |li| li.order },
          sort_by: proc { |order|  order.completed_at } } ]
      else
        [ { group_by: proc { |li| li.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |li| li.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| lis.first.product.supplier.name },
          proc { |lis| lis.first.product.name },
          proc { |lis| lis.first.product.group_buy_unit_size || 0.0 },
          proc { |lis| "" },
          proc { |lis| "" },
          proc { |lis| lis.sum { |li| li.quantity * (li.weight_from_unit_value || 0) } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.weight_from_unit_value || 0) } },
          proc { |lis| ( (lis.first.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.weight_from_unit_value || 0) } / lis.first.product.group_buy_unit_size ) ).floor },
          proc { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.weight_from_unit_value || 0) } - ( ( (lis.first.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.weight_from_unit_value || 0) } / lis.first.product.group_buy_unit_size ) ).floor * (lis.first.product.group_buy_unit_size || 0) ) } ] },
        { group_by: proc { |li| li.full_name },
        sort_by: proc { |full_name| full_name } } ]
      end
    end

    def columns
      case params[:report_type]
      when "bulk_coop_supplier_report"
        @supplier_report.columns
      when "bulk_coop_allocation"
        @allocation_report.columns
      when "bulk_coop_packing_sheets"
        [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
          proc { |lis| lis.first.product.name },
          proc { |lis| lis.first.full_name },
          proc { |lis|  lis.sum { |li| li.quantity } } ]
      when "bulk_coop_customer_payments"
        [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
          proc { |lis| lis.first.order.completed_at.to_s },
          proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.total } },
          proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.outstanding_balance } },
          proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.payment_total } } ]
      else
        [ proc { |lis| lis.first.product.supplier.name },
          proc { |lis| lis.first.product.name },
          proc { |lis| lis.first.product.group_buy_unit_size || 0.0 },
          proc { |lis| lis.first.full_name },
          proc { |lis| lis.first.weight_from_unit_value || 0 },
          proc { |lis| lis.sum { |li| li.quantity } },
          proc { |lis| lis.sum { |li| li.max_quantity || 0 } },
          proc { |lis| "" },
          proc { |lis| "" } ]
      end
    end

    private

    def permissions
      return @permissions unless @permissions.nil?
      @permissions = OpenFoodNetwork::Permissions.new(@user)
    end
  end
end
