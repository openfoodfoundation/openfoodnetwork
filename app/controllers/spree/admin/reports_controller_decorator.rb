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

  # Fetches user's distributors, suppliers and order_cycles
  before_filter :load_data, only: [:customers, :products_and_inventory, :order_cycle_management, :packing]

  def report_types
    {
      orders_and_fulfillment: [
        [I18n.t('admin.reports.supplier_totals'), :order_cycle_supplier_totals],
        [I18n.t('admin.reports.supplier_totals_by_distributor'), :order_cycle_supplier_totals_by_distributor],
        [I18n.t('admin.reports.totals_by_supplier'), :order_cycle_distributor_totals_by_supplier],
        [I18n.t('admin.reports.customer_totals'), :order_cycle_customer_totals]
      ],
      products_and_inventory: [
        [I18n.t('admin.reports.all_products'), :all_products],
        [I18n.t('admin.reports.inventory'), :inventory],
        [I18n.t('admin.reports.lettuce_share'), :lettuce_share]
      ],
      customers: [
        [I18n.t('admin.reports.mailing_list'), :mailing_list],
        [I18n.t('admin.reports.addresses'), :addresses]
      ],
      order_cycle_management: [
        [I18n.t('admin.reports.payment_methods'), :payment_methods],
        [I18n.t('admin.reports.delivery'), :delivery]
      ],
      sales_tax: [
        [I18n.t('admin.reports.tax_types'), :tax_types],
        [I18n.t('admin.reports.tax_rates'), :tax_rates]
      ],
      packing: [
        [I18n.t('admin.reports.pack_by_customer'), :pack_by_customer],
        [I18n.t('admin.reports.pack_by_supplier'), :pack_by_supplier]
      ]
    }
  end

  # Overide spree reports list.
  def index
    @reports = authorized_reports
    respond_with(@reports)
  end

  # This action is short because we refactored it like bosses
  def customers
    @report_types = report_types[:customers]
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

    @report_types = report_types[:order_cycle_management]
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::OrderCycleManagementReport.new spree_current_user, params
    @table = @report.table_items

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
    @report_types = report_types[:packing]
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::PackingReport.new spree_current_user, params
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)

    render_report(@report.header, @table, params[:csv], "packing_#{timestamp}.csv")
  end

  def orders_and_distributors
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
      order.bill_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
      order.ship_address.andand.assign_attributes(firstname: I18n.t('admin.reports.hidden'), lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
      order.assign_attributes(email: I18n.t('admin.reports.hidden'))
    end

    @report = OpenFoodNetwork::OrderAndDistributorReport.new orders
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
    # -- Prepare date parameters
    prepare_date_params params

    # -- Prepare form options
    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::BulkCoopReport.new spree_current_user, params
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)
    csv_file_name = "bulk_coop_#{params[:report_type]}_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], csv_file_name)
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
    # -- Prepare Date Params
    prepare_date_params params

    # -- Prepare Form Options
    permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    # My distributors and any distributors distributing products I supply
    @distributors = permissions.visible_enterprises_for_order_reports.is_distributor
    # My suppliers and any suppliers supplying products I distribute
    @suppliers = permissions.visible_enterprises_for_order_reports.is_primary_producer

    @order_cycles = OrderCycle.active_or_complete.
      involving_managed_distributors_of(spree_current_user).order('orders_close_at DESC')

    @report_types = report_types[:orders_and_fulfillment]
    @report_type = params[:report_type]

    @include_blank = I18n.t(:all)

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::OrdersAndFulfillmentsReport.new spree_current_user, params
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)
    csv_file_name = "#{params[:report_type]}_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], csv_file_name)

  end

  def products_and_inventory
    @report_types = report_types[:products_and_inventory]
    if params[:report_type] != 'lettuce_share'
      @report = OpenFoodNetwork::ProductsAndInventoryReport.new spree_current_user, params
    else
      @report = OpenFoodNetwork::LettuceShareReport.new spree_current_user, params
    end
    render_report(@report.header, @report.table, params[:csv], "products_and_inventory_#{timestamp}.csv")
  end

  def users_and_enterprises
    # @report_types = report_types[:users_and_enterprises]
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
      :orders_and_distributors => {:name => I18n.t('admin.reports.orders_and_distributors.name'), :description => I18n.t('admin.reports.orders_and_distributors.description')},
      :bulk_coop => {:name => I18n.t('admin.reports.bulk_coop.name'), :description => I18n.t('admin.reports.bulk_coop.description')},
      :payments => {:name => I18n.t('admin.reports.payments.name'), :description => I18n.t('admin.reports.payments.description')},
      :orders_and_fulfillment => {:name => I18n.t('admin.reports.orders_and_fulfillment.name'), :description => ''},
      :customers => {:name => I18n.t('admin.reports.customers.name'), :description => ''},
      :products_and_inventory => {:name => I18n.t('admin.reports.products_and_inventory.name'), :description => ''},
      :sales_total => {:name => I18n.t('admin.reports.sales_total.name'), :description => I18n.t('admin.reports.sales_total.description')},
      :users_and_enterprises => {:name => I18n.t('admin.reports.users_and_enterprises.name'), :description => I18n.t('admin.reports.users_and_enterprises.description')},
      :order_cycle_management => {:name => I18n.t('admin.reports.order_cycle_management.name'), :description => ''},
      :sales_tax => {:name => I18n.t('admin.reports.sales_tax.name'), :description => ''},
      :xero_invoices => {:name => I18n.t('admin.reports.xero_invoices.name'), :description => I18n.t('admin.reports.xero_invoices.description')},
      :packing => {:name => I18n.t('admin.reports.packing.name'), :description => ''}
    }

    reports[:orders_and_fulfillment][:description] =
      render_to_string(partial: 'orders_and_fulfillment_description', layout: false, locals: {report_types: report_types[:orders_and_fulfillment]}).html_safe
    reports[:products_and_inventory][:description] =
      render_to_string(partial: 'products_and_inventory_description', layout: false, locals: {report_types: report_types[:products_and_inventory]}).html_safe
    reports[:customers][:description] =
      render_to_string(partial: 'customers_description', layout: false, locals: {report_types: report_types[:customers]}).html_safe
    reports[:order_cycle_management][:description] =
      render_to_string(partial: 'order_cycle_management_description', layout: false, locals: {report_types: report_types[:order_cycle_management]}).html_safe
    reports[:packing][:description] =
        render_to_string(partial: 'packing_description', layout: false, locals: {report_types: report_types[:packing]}).html_safe
    reports[:sales_tax][:description] =
        render_to_string(partial: 'sales_tax_description', layout: false, locals: {report_types: report_types[:sales_tax]}).html_safe

    # Return only reports the user is authorized to view.
    reports.select { |action| can? action, :report }
  end

  def timestamp
    Time.zone.now.strftime("%Y%m%d")
  end
end
