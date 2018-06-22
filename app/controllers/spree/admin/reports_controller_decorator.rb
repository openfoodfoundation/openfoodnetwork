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

  helper_method :render_content?

  before_filter :cache_search_state
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

  # Override spree reports list.
  def index
    @reports = authorized_reports
    respond_with(@reports)
  end

  def customers
    @report_types = report_types[:customers]
    @report_type = params[:report_type]
    @report = OpenFoodNetwork::CustomersReport.new spree_current_user, params, render_content?
    render_report(@report.header, @report.table, params[:csv], "customers_#{timestamp}.csv")
  end

  def order_cycle_management
    params[:q] ||= {}

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
    @report = OpenFoodNetwork::OrderCycleManagementReport.new spree_current_user, params, render_content?
    @table = @report.table_items

    render_report(@report.header, @table, params[:csv], "order_cycle_management_#{timestamp}.csv")
  end

  def packing
    params[:q] ||= {}

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
    @report = OpenFoodNetwork::PackingReport.new spree_current_user, params, render_content?
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)

    render_report(@report.header, @table, params[:csv], "packing_#{timestamp}.csv")
  end

  def orders_and_distributors
    @report = OpenFoodNetwork::OrderAndDistributorReport.new spree_current_user, params, render_content?
    @search = @report.search
    csv_file_name = "orders_and_distributors_#{timestamp}.csv"
    render_report(@report.header, @report.table, params[:csv], csv_file_name)
  end

  def sales_tax
    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @report_type = params[:report_type]
    @report = OpenFoodNetwork::SalesTaxReport.new spree_current_user, params, render_content?
    render_report(@report.header, @report.table, params[:csv], "sales_tax.csv")
  end

  def bulk_coop
    # -- Prepare form options
    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::BulkCoopReport.new spree_current_user, params, render_content?
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)
    csv_file_name = "bulk_coop_#{params[:report_type]}_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], csv_file_name)
  end

  def payments
    # -- Prepare Form Options
    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::PaymentsReport.new spree_current_user, params, render_content?
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)
    csv_file_name = "payments_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], csv_file_name)
  end

  def orders_and_fulfillment
    params[:q] ||= {}

    # -- Prepare Form Options
    permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    # My distributors and any distributors distributing products I supply
    @distributors = permissions.visible_enterprises_for_order_reports.is_distributor
    # My suppliers and any suppliers supplying products I distribute
    @suppliers = permissions.visible_enterprises_for_order_reports.is_primary_producer

    @order_cycles = OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')

    @report_types = report_types[:orders_and_fulfillment]
    @report_type = params[:report_type]

    @include_blank = I18n.t(:all)

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::OrdersAndFulfillmentsReport.new spree_current_user, params, render_content?
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    @table = order_grouper.table(@report.table_items)
    csv_file_name = "#{params[:report_type]}_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], csv_file_name)
  end

  def products_and_inventory
    @report_types = report_types[:products_and_inventory]
    @report = if params[:report_type] != 'lettuce_share'
                OpenFoodNetwork::ProductsAndInventoryReport.new spree_current_user, params, render_content?
              else
                OpenFoodNetwork::LettuceShareReport.new spree_current_user, params, render_content?
              end
    render_report(@report.header, @report.table, params[:csv], "products_and_inventory_#{timestamp}.csv")
  end

  def users_and_enterprises
    @report = OpenFoodNetwork::UsersAndEnterprisesReport.new params, render_content?
    render_report(@report.header, @report.table, params[:csv], "users_and_enterprises_#{timestamp}.csv")
  end

  def xero_invoices
    params[:q] ||= {}

    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @order_cycles = OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')

    @report = OpenFoodNetwork::XeroInvoicesReport.new spree_current_user, params, render_content?
    render_report(@report.header, @report.table, params[:csv], "xero_invoices_#{timestamp}.csv")
  end

  private

  # Some actions are changing the `params` object. That is unfortunate Spree
  # behavior and we are building on it. So we have to look at `params` early
  # to check if we are searching or just displaying a report search form.
  def cache_search_state
    search_keys = [
      # search parameter for ransack
      :q,
      # common in all reports, only set for CSV rendering
      :csv,
      # `button` is included in all forms. It's not important for searching,
      # but the Users & Enterprises report doesn't have any other parameter
      # for an empty search. So we use this one to display data.
      :button,
      # Some reports use filtering by enterprise or order cycle
      :distributor_id,
      :supplier_id,
      :order_cycle_id,
      # Xero Invoices can be filtered by date
      :invoice_date,
      :due_date
    ]
    @searching = search_keys.any? { |key| params.key? key }
  end

  # We don't want to render data unless search params are supplied.
  # Compiling data can take a long time.
  def render_content?
    @searching
  end

  def render_report(header, table, create_csv, csv_file_name)
    send_data csv_report(header, table), filename: csv_file_name if create_csv
    @header = header
    @table = table
    # Rendering HTML is the default.
  end

  def csv_report(header, table)
    CSV.generate do |csv|
      csv << header
      table.each { |row| csv << row }
    end
  end

  def load_data
    # Load distributors either owned by the user or selling their enterprises products.
    my_distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    my_suppliers = Enterprise.is_primary_producer.managed_by(spree_current_user)
    distributors_of_my_products = Enterprise.with_distributed_products_outer.merge(Spree::Product.in_any_supplier(my_suppliers))
    @distributors = my_distributors | distributors_of_my_products
    # Load suppliers either owned by the user or supplying products their enterprises distribute.
    suppliers_of_products_i_distribute = my_distributors.map { |d| Spree::Product.in_distributor(d) }.flatten.map(&:supplier).uniq
    @suppliers = my_suppliers | suppliers_of_products_i_distribute
    @order_cycles = OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')
  end

  def authorized_reports
    all_reports = [
      :orders_and_distributors,
      :bulk_coop,
      :payments,
      :orders_and_fulfillment,
      :customers,
      :products_and_inventory,
      :sales_total,
      :users_and_enterprises,
      :order_cycle_management,
      :sales_tax,
      :xero_invoices,
      :packing
    ]
    reports = all_reports.select { |action| can? action, :report }
    reports.map { |report| [report, describe_report(report)] }.to_h
  end

  def describe_report(report)
    name = I18n.t(:name, scope: [:admin, :reports, report])
    description = begin
      I18n.t!(:description, scope: [:admin, :reports, report])
    rescue I18n::MissingTranslationData
      render_to_string(
        partial: "#{report}_description",
        layout: false,
        locals: { report_types: report_types[report] }
      ).html_safe
    end
    { name: name, description: description }
  end

  def timestamp
    Time.zone.now.strftime("%Y%m%d")
  end
end
