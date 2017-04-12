require 'csv'
require 'open_food_network/order_and_distributor_report'
require 'open_food_network/products_and_inventory_report'
require 'open_food_network/lettuce_share_report'
require 'open_food_network/group_buy_report'
require 'open_food_network/order_grouper'
require 'open_food_network/customers_report'
require 'open_food_network/users_and_enterprises_report'
require 'open_food_network/order_cycle_management_report'
require 'open_food_network/packing_report'
require 'open_food_network/sales_tax_report'
require 'open_food_network/xero_invoices_report'
require 'open_food_network/bulk_coop_report'
require 'open_food_network/payments_report'
require 'open_food_network/orders_and_fulfillments_report'

Spree::Admin::ReportsController.class_eval do

  include Spree::ReportsHelper

  respond_to :json

  REPORT_TYPES = {
    orders_and_fulfillment: [
      ['Order Cycle Supplier Totals', :supplier_totals],
      ['Order Cycle Supplier Totals by Distributor', :supplier_totals_by_distributor],
      ['Order Cycle Distributor Totals by Supplier', :distributor_totals_by_supplier],
      ['Order Cycle Customer Totals', :customer_totals]
    ],
    products_and_inventory: [
      ['All products', :all_products],
      ['Inventory (on hand)', :inventory],
      ['LettuceShare', :lettuce_share]
    ],
    customers: [
      ["Mailing List", :mailing_list],
      ["Addresses", :addresses]
    ],
    order_cycle_management: [
      ["Payment Methods Report", :payment_methods],
      ["Delivery Report", :delivery]
    ],
    sales_tax: [
      ["Tax Types", :tax_types],
      ["Tax Rates", :tax_rates]
    ],
    packing: [
      ["Pack By Customer", :pack_by_customer],
      ["Pack By Supplier", :pack_by_supplier]
    ],
    bulk_coop: [
      ['Bulk Co-op - Totals by Supplier', :supplier_report],
      ['Bulk Co-op - Allocation', :allocation],
      ['Bulk Co-op - Packing Sheets', :packing_sheets],
      ['Bulk Co-op - Customer Payments', :customer_payments]
    ]
  }

  # Fetches user's distributors, suppliers and order_cycles
  before_filter :load_data, only: [:customers, :products_and_inventory, :order_cycle_management, :packing]

  # Render a partial for orders and fulfillment description
  respond_override :index => { :html => { :success => lambda {
    @reports[:orders_and_fulfillment][:description] =
      render_to_string(partial: 'orders_and_fulfillment_description', layout: false, locals: {report_types: REPORT_TYPES[:orders_and_fulfillment]}).html_safe
    @reports[:products_and_inventory][:description] =
      render_to_string(partial: 'products_and_inventory_description', layout: false, locals: {report_types: REPORT_TYPES[:products_and_inventory]}).html_safe
    @reports[:customers][:description] =
      render_to_string(partial: 'customers_description', layout: false, locals: {report_types: REPORT_TYPES[:customers]}).html_safe
    @reports[:order_cycle_management][:description] =
      render_to_string(partial: 'order_cycle_management_description', layout: false, locals: {report_types: REPORT_TYPES[:order_cycle_management]}).html_safe
    @reports[:packing][:description] =
        render_to_string(partial: 'packing_description', layout: false, locals: {report_types: REPORT_TYPES[:packing]}).html_safe
    @reports[:sales_tax][:description] =
        render_to_string(partial: 'sales_tax_description', layout: false, locals: {report_types: REPORT_TYPES[:sales_tax]}).html_safe
} } }


  # Overide spree reports list.
  def index
    @reports = authorized_reports
    respond_with(@reports)
  end

  # This action is short because we refactored it like bosses
  def customers
    @report_types = REPORT_TYPES[:customers]
    @report_type = params[:report_type]
    @report = OpenFoodNetwork::CustomersReport.new spree_current_user, params
    render_report(@report.header, @report.table, params[:csv], "customers_#{timestamp}.csv")
  end

  def order_cycle_management
    prepare_date_params params

    # -- Prepare form options
    my_distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    my_suppliers = Enterprise.is_primary_producer.managed_by(spree_current_user)

    # My distributors and any distributors distributing products I supply
    @distributors = my_distributors | Enterprise.with_distributed_products_outer.merge(Spree::Product.in_any_supplier(my_suppliers))
    # My suppliers and any suppliers supplying products I distribute
    @suppliers = my_suppliers | my_distributors.map { |d| Spree::Product.in_distributor(d) }.flatten.map(&:supplier).uniq
    @order_cycles = OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')

    @report_types = REPORT_TYPES[:order_cycle_management]
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::OrderCycleManagementReport.new spree_current_user, params
    @table = @report.table_items
    csv_file_name = "#{params[:report_type]}_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], "order_cycle_management_#{timestamp}.csv")
  end

  def packing
    # -- Prepare date parameters
    prepare_date_params params

    # -- Prepare form options
    my_distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    my_suppliers = Enterprise.is_primary_producer.managed_by(spree_current_user)

    # My distributors and any distributors distributing products I supply
    @distributors = my_distributors | Enterprise.with_distributed_products_outer.merge(Spree::Product.in_any_supplier(my_suppliers))
    # My suppliers and any suppliers supplying products I distribute
    @suppliers = my_suppliers | my_distributors.map { |d| Spree::Product.in_distributor(d) }.flatten.map(&:supplier).uniq
    @order_cycles = OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')
    @report_types = REPORT_TYPES[:packing]
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::PackingReport.new spree_current_user, params
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)
    csv_file_name = "#{params[:report_type]}_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], "packing_#{timestamp}.csv")
  end

  def orders_and_distributors
    if request.format.json?
      prepare_date_params params
      @report = OpenFoodNetwork::OrderAndDistributorReport.new spree_current_user, params
      line_items = @report.table_items
      orders = Spree::Order.joins(:line_items).where(spree_line_items: { id: line_items.pluck(:id) }).select('DISTINCT spree_orders.*')
      variants = Spree::Variant.joins(:line_items).where(spree_line_items: { id: line_items.pluck(:id) }).select('DISTINCT spree_variants.*')
      products = Spree::Product.joins(:all_variants).where(spree_variants: { id: variants.pluck(:id) }).select('DISTINCT spree_products.*')
      distributors = Enterprise.joins(:distributed_orders).where(spree_orders: { id: orders.pluck(:id) }).select('DISTINCT enterprises.*')

      line_items = ActiveModel::ArraySerializer.new(line_items, each_serializer: Api::Admin::Reports::LineItemSerializer)
      orders = ActiveModel::ArraySerializer.new(orders, each_serializer: Api::Admin::Reports::OrderSerializer)
      products = ActiveModel::ArraySerializer.new(products, each_serializer: Api::Admin::Reports::ProductSerializer)
      distributors = ActiveModel::ArraySerializer.new(distributors, each_serializer: Api::Admin::Reports::EnterpriseSerializer)
      variants = ActiveModel::ArraySerializer.new(variants, each_serializer: Api::Admin::Reports::VariantSerializer)

      report_data = { line_items: line_items, orders: orders, products: products, distributors: distributors, variants: variants }
      render json: report_data
    else
      @show_old_version = params[:show_old_version] == '1' || false
      prepare_date_params params

      permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
      @search = permissions.visible_orders.complete.not_state(:canceled).search(params[:q])
      orders = @search.result

      # If empty array is passed in, the where clause will return all line_items, which is bad
      orders_with_hidden_details =
        permissions.editable_orders.empty? ? orders : orders.where('id NOT IN (?)', permissions.editable_orders)

      orders.select{ |order| orders_with_hidden_details.include? order }.each do |order|
        # TODO We should really be hiding customer code here too, but until we
        # have an actual association between order and customer, it's a bit tricky
        order.bill_address.andand.assign_attributes(firstname: "HIDDEN", lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        order.ship_address.andand.assign_attributes(firstname: "HIDDEN", lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        order.assign_attributes(email: "HIDDEN")
      end

      @report = OpenFoodNetwork::OrderAndDistributorReport.new spree_current_user, params, orders
      unless params[:csv]
        render :html => @report
      else
        csv_string = CSV.generate do |csv|
          csv << @report.header
          @report.table.each { |row| csv << row }
        end
        send_data csv_string, :filename => "orders_and_distributors_#{timestamp}.csv"
      end
    end
  end

  def sales_tax
    prepare_date_params params
    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @report_type = params[:report_type]

    @report = OpenFoodNetwork::SalesTaxReport.new spree_current_user, params

    unless params[:csv]
      render :html => @report
    else
      csv_string = CSV.generate do |csv|
        csv << @report.header
        @report.table.each { |row| csv << row }
      end
      send_data csv_string, :filename => "sales_tax.csv"
    end
  end

  def bulk_coop
    if request.format.json?
      # -- Prepare date parameters
      prepare_date_params params
      @report = OpenFoodNetwork::BulkCoopReport.new spree_current_user, params
      line_items = @report.table_items

      orders = Spree::Order.joins(:line_items).where(spree_line_items: { id: line_items.pluck(:id) }).select('DISTINCT spree_orders.*')
      variants = Spree::Variant.joins(:line_items).where(spree_line_items: { id: line_items.pluck(:id) }).select('DISTINCT spree_variants.*')
      products = Spree::Product.joins(:all_variants).where(spree_variants: { id: variants.pluck(:id) }).select('DISTINCT spree_products.*')
      distributors = Enterprise.joins(:distributed_orders).where(spree_orders: { id: orders.pluck(:id) }).select('DISTINCT enterprises.*')

      line_items = ActiveModel::ArraySerializer.new(line_items, each_serializer: Api::Admin::Reports::LineItemSerializer)
      orders = ActiveModel::ArraySerializer.new(orders, each_serializer: Api::Admin::Reports::OrderSerializer)
      products = ActiveModel::ArraySerializer.new(products, each_serializer: Api::Admin::Reports::ProductSerializer)
      distributors = ActiveModel::ArraySerializer.new(distributors, each_serializer: Api::Admin::Reports::EnterpriseSerializer)
      variants = ActiveModel::ArraySerializer.new(variants, each_serializer: Api::Admin::Reports::VariantSerializer)

      report_data = { line_items: line_items, orders: orders, products: products, distributors: distributors, variants: variants }
      render json: report_data
    else
      @show_old_version = params[:show_old_version] == '1' || false
      # -- Prepare date parameters
      prepare_date_params params
      @report_types = REPORT_TYPES[:bulk_coop]
      @report_type = params[:q].andand[:report_type]
      # -- Prepare form options
      @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
      @report_type = params[:report_type] || @report_types.first.last

      # -- Build Report with Order Grouper
      @report = OpenFoodNetwork::BulkCoopReport.new spree_current_user, params
      order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
      @table = order_grouper.table(@report.table_items)
      csv_file_name = "bulk_coop_#{params[:report_type]}_#{timestamp}.csv"

      render_report(@report.header, @table, params[:csv], csv_file_name)
    end
  end

  def payments
    # -- Prepare Date Params
    prepare_date_params params

    # -- Prepare Form Options
    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::PaymentsReport.new spree_current_user, params
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)
    csv_file_name = "payments_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], csv_file_name)
  end

  def orders_and_fulfillment
    if request.format.json?
      # -- Prepare Date Params
      prepare_date_params params
      @report = OpenFoodNetwork::OrdersAndFulfillmentsReport.new spree_current_user, params
      line_items = @report.table_items
      orders = Spree::Order.joins(:line_items).where(spree_line_items: { id: line_items.pluck(:id) }).select('DISTINCT spree_orders.*')
      variants = Spree::Variant.joins(:line_items).where(spree_line_items: { id: line_items.pluck(:id) }).select('DISTINCT spree_variants.*')
      products = Spree::Product.joins(:all_variants).where(spree_variants: { id: variants.pluck(:id) }).select('DISTINCT spree_products.*')

      line_items = ActiveModel::ArraySerializer.new(line_items, each_serializer: Api::Admin::Reports::LineItemSerializer)
      orders = ActiveModel::ArraySerializer.new(orders, each_serializer: Api::Admin::Reports::OrderSerializer)
      variants = ActiveModel::ArraySerializer.new(variants, each_serializer: Api::Admin::Reports::VariantSerializer)
      products = ActiveModel::ArraySerializer.new(products, each_serializer: Api::Admin::Reports::ProductSerializer)

      report_data = { line_items: line_items, orders: orders, variants: variants, products: products}
      render json: report_data
    else
      @show_old_version = params[:show_old_version] == '1' || false
      prepare_date_params params

      # -- Prepare Form Options
      permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
      # My distributors and any distributors distributing products I supply
      @shops = permissions.visible_enterprises_for_order_reports.is_distributor
      # My suppliers and any suppliers supplying products I distribute
      @producers = permissions.visible_enterprises_for_order_reports.is_primary_producer

      @order_cycles = OrderCycle.active_or_complete.
      involving_managed_distributors_of(spree_current_user).order('orders_close_at DESC')

      @report_types = REPORT_TYPES[:orders_and_fulfillment]
      @report_type = params[:report_type] || @report_types.first.last

      @include_blank = 'All'

      # -- Build Report with Order Grouper
      @report = OpenFoodNetwork::OrdersAndFulfillmentsReport.new spree_current_user, params
      order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
      @table = order_grouper.table(@report.table_items)
      csv_file_name = "#{params[:report_type]}_#{timestamp}.csv"

      render_report(@report.header, @table, params[:csv], csv_file_name)

    end

  end

  def products_and_inventory
    @report_types = REPORT_TYPES[:products_and_inventory]
    if params[:report_type] != 'lettuce_share'
      @report = OpenFoodNetwork::ProductsAndInventoryReport.new spree_current_user, params
    else
      @report = OpenFoodNetwork::LettuceShareReport.new spree_current_user, params
    end
    render_report(@report.header, @report.table, params[:csv], "products_and_inventory_#{timestamp}.csv")
  end

  def users_and_enterprises
    # @report_types = REPORT_TYPES[:users_and_enterprises]
    @report = OpenFoodNetwork::UsersAndEnterprisesReport.new params
    render_report(@report.header, @report.table, params[:csv], "users_and_enterprises_#{timestamp}.csv")
  end

  def xero_invoices
    if request.get?
      params[:q] ||= {}
      params[:q][:completed_at_gt] = Time.zone.today.beginning_of_month
      params[:invoice_date] = Time.zone.today
      params[:due_date] = Time.zone.today + 1.month
    end
    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @order_cycles = OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')

    @report = OpenFoodNetwork::XeroInvoicesReport.new spree_current_user, params
    render_report(@report.header, @report.table, params[:csv], "xero_invoices_#{timestamp}.csv")
  end


  def render_report(header, table, create_csv, csv_file_name)
    unless create_csv
      render :html => table
    else
      csv_string = CSV.generate do |csv|
        csv << header
       table.each { |row| csv << row }
      end
      send_data csv_string, :filename => csv_file_name
    end
  end

  private

  def prepare_date_params(params)
    # -- Prepare parameters
    params[:q] ||= {}
    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]) rescue Time.zone.now.beginning_of_month
    end
    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]) rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"
  end

  def load_data
    # Load distributors either owned by the user or selling their enterprises products.
    my_distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    my_suppliers = Enterprise.is_primary_producer.managed_by(spree_current_user)
    distributors_of_my_products = Enterprise.with_distributed_products_outer.merge(Spree::Product.in_any_supplier(my_suppliers))
    @distributors = my_distributors | distributors_of_my_products
    # Load suppliers either owned by the user or supplying products their enterprises distribute.
    suppliers_of_products_I_distribute = my_distributors.map { |d| Spree::Product.in_distributor(d) }.flatten.map(&:supplier).uniq
    @suppliers = my_suppliers | suppliers_of_products_I_distribute
    @order_cycles = OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')
  end

  def authorized_reports
    reports = {
      :orders_and_distributors => {:name => "Orders And Distributors", :description => "Orders with distributor details"},
      :bulk_coop => {:name => "Bulk Co-Op", :description => "Reports for Bulk Co-Op orders"},
      :payments => {:name => "Payment Reports", :description => "Reports for Payments"},
      :orders_and_fulfillment => {:name => "Orders & Fulfillment Reports", :description => ''},
      :customers => {:name => "Customers", :description => 'Customer details'},
      :products_and_inventory => {:name => "Products & Inventory", :description => ''},
      :sales_total => { :name => "Sales Total", :description => "Sales Total For All Orders" },
      :users_and_enterprises => { :name => "Users & Enterprises", :description => "Enterprise Ownership & Status" },
      :order_cycle_management => {:name => "Order Cycle Management", :description => ''},
      :sales_tax => { :name => "Sales Tax", :description => "Sales Tax For Orders" },
      :xero_invoices => { :name => "Xero Invoices", :description => 'Invoices for import into Xero' },
      :packing => { :name => "Packing Reports", :description => '' }
    }
    # Return only reports the user is authorized to view.
    reports.select { |action| can? action, :report }
  end

  def timestamp
    Time.zone.now.strftime("%Y%m%d")
  end
end
