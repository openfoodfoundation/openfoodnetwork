require 'csv'

require 'open_food_network/reports/list'
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
    OpenFoodNetwork::Reports::List.all
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

    @report_types = report_types[:order_cycle_management]
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::OrderCycleManagementReport.new spree_current_user, params, render_content?
    @table = @report.table_items

    render_report(@report.header, @table, params[:csv], "order_cycle_management_#{timestamp}.csv")
  end

  def packing
    params[:q] ||= {}

    @report_types = report_types[:packing]
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::PackingReport.new spree_current_user, params, render_content?
    @table = order_grouper_table

    render_report(@report.header, @table, params[:csv], "packing_#{timestamp}.csv")
  end

  def orders_and_distributors
    @report = OpenFoodNetwork::OrderAndDistributorReport.new spree_current_user, params, render_content?
    @search = @report.search
    csv_file_name = "orders_and_distributors_#{timestamp}.csv"
    render_report(@report.header, @report.table, params[:csv], csv_file_name)
  end

  def sales_tax
    @distributors = my_distributors
    @report_type = params[:report_type]
    @report = OpenFoodNetwork::SalesTaxReport.new spree_current_user, params, render_content?
    render_report(@report.header, @report.table, params[:csv], "sales_tax.csv")
  end

  def bulk_coop
    # -- Prepare form options
    @distributors = my_distributors
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::BulkCoopReport.new spree_current_user, params, render_content?
    @table = order_grouper_table
    csv_file_name = "bulk_coop_#{params[:report_type]}_#{timestamp}.csv"

    render_report(@report.header, @table, params[:csv], csv_file_name)
  end

  def payments
    # -- Prepare Form Options
    @distributors = my_distributors
    @report_type = params[:report_type]

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::PaymentsReport.new spree_current_user, params, render_content?
    @table = order_grouper_table
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

    @order_cycles = my_order_cycles

    @report_types = report_types[:orders_and_fulfillment]
    @report_type = params[:report_type]

    @include_blank = I18n.t(:all)

    # -- Build Report with Order Grouper
    @report = OpenFoodNetwork::OrdersAndFulfillmentsReport.new spree_current_user, params, render_content?
    @table = order_grouper_table
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

    @distributors = my_distributors
    @order_cycles = my_order_cycles

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
    @distributors = my_distributors
    @suppliers = my_suppliers | suppliers_of_products_distributed_by(@distributors)
    @order_cycles = my_order_cycles
  end

  # Load managed distributor enterprises of current user
  def my_distributors
    Enterprise.is_distributor.managed_by(spree_current_user)
  end

  # Load managed producer enterprises of current user
  def my_suppliers
    Enterprise.is_primary_producer.managed_by(spree_current_user)
  end

  def suppliers_of_products_distributed_by(distributors)
    distributors.map { |d| Spree::Product.in_distributor(d) }.flatten.map(&:supplier).uniq
  end

  # Load order cycles the current user has access to
  def my_order_cycles
    OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')
  end

  def order_grouper_table
    order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns
    order_grouper.table(@report.table_items)
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
      :enterprise_fee_summary,
      :order_cycle_management,
      :sales_tax,
      :xero_invoices,
      :packing
    ]
    reports = all_reports.select { |action| can? action, Spree::Admin::ReportsController }
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
    { name: name, url: url_for_report(report), description: description }
  end

  def url_for_report(report)
    public_send("#{report}_admin_reports_url".to_sym)
  rescue NoMethodError
    url_for([:new, :admin, :reports, report.to_s.singularize])
  end

  def timestamp
    Time.zone.now.strftime("%Y%m%d")
  end
end
