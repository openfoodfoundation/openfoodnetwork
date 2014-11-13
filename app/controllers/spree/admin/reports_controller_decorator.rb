require 'csv'
require 'open_food_network/order_and_distributor_report'
require 'open_food_network/products_and_inventory_report'
require 'open_food_network/group_buy_report'
require 'open_food_network/order_grouper'
require 'open_food_network/customers_report'

Spree::Admin::ReportsController.class_eval do

  REPORT_TYPES = {
    orders_and_fulfillment: [
      ['Order Cycle Supplier Totals',:order_cycle_supplier_totals],
      ['Order Cycle Supplier Totals by Distributor',:order_cycle_supplier_totals_by_distributor],
      ['Order Cycle Distributor Totals by Supplier',:order_cycle_distributor_totals_by_supplier],
      ['Order Cycle Customer Totals',:order_cycle_customer_totals]
    ],
    products_and_inventory: [
      ['All products', :all_products],
      ['Inventory (on hand)', :inventory]
    ],
    customers: [
      ["Mailing List", :mailing_list],
      ["Addresses", :addresses]
    ]
  }

  # Fetches user's distributors, suppliers and order_cycles
  before_filter :load_data, only: [:customers, :products_and_inventory]

  # Render a partial for orders and fulfillment description
  respond_override :index => { :html => { :success => lambda {
    @reports[:orders_and_fulfillment][:description] =
      render_to_string(partial: 'orders_and_fulfillment_description', layout: false, locals: {report_types: REPORT_TYPES[:orders_and_fulfillment]}).html_safe
    @reports[:products_and_inventory][:description] =
      render_to_string(partial: 'products_and_inventory_description', layout: false, locals: {report_types: REPORT_TYPES[:products_and_inventory]}).html_safe
    @reports[:customers][:description] =
      render_to_string(partial: 'customers_description', layout: false, locals: {report_types: REPORT_TYPES[:customers]}).html_safe
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

    render_report(@report.header, @report.table, params[:csv], "customers.csv")
  end

  def orders_and_distributors
    params[:q] = {} unless params[:q]

    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"

    @search = Spree::Order.complete.not_state(:canceled).managed_by(spree_current_user).search(params[:q])
    orders = @search.result

    @report = OpenFoodNetwork::OrderAndDistributorReport.new orders
    unless params[:csv]
      render :html => @report
    else
      csv_string = CSV.generate do |csv|
        csv << @report.header
        @report.table.each { |row| csv << row }
      end
      send_data csv_string, :filename => "orders_and_distributors.csv"
    end
  end

  def bulk_coop
    params[:q] = {} unless params[:q]

    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"

    @search = Spree::Order.complete.not_state(:canceled).managed_by(spree_current_user).search(params[:q])

    orders = @search.result
    @line_items = orders.map { |o| o.line_items.managed_by(spree_current_user) }.flatten

    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @report_type = params[:report_type]

    case params[:report_type]
    when "bulk_coop_supplier_report"

      header = ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Units Required", "Remainder"]

      columns = [ proc { |lis| lis.first.variant.product.supplier.name },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
        proc { |lis| lis.first.variant.full_name },
        proc { |lis| lis.first.variant.weight || 0 },
        proc { |lis|  lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } },
        proc { |lis| "" },
        proc { |lis| "" } ]

      rules = [ { group_by: proc { |li| li.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| lis.first.variant.product.supplier.name },
          proc { |lis| lis.first.variant.product.name },
          proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
          proc { |lis| "" },
          proc { |lis| "" },
          proc { |lis| lis.sum { |li| (li.quantity || 0) * (li.variant.weight || 0) } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.variant.weight || 0) } },
          proc { |lis| ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor },
          proc { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max) * (li.variant.weight || 0) } - ( ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) ) } ] },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.full_name } } ]

    when "bulk_coop_allocation"

      header = ["Customer", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Total Allocated", "Remainder"]

      columns = [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
        proc { |lis| lis.first.variant.full_name },
        proc { |lis| lis.first.variant.weight || 0 },
        proc { |lis| lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } },
        proc { |lis| "" },
        proc { |lis| "" } ]

      rules = [ { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| "TOTAL" },
          proc { |lis| lis.first.variant.product.name },
          proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
          proc { |lis| "" },
          proc { |lis| "" },
          proc { |lis| lis.sum { |li| li.quantity * (li.variant.weight || 0) } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.variant.weight || 0) } },
          proc { |lis| ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) },
          proc { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } - ( ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) ) } ] },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.full_name } },
        { group_by: proc { |li| li.order },
        sort_by: proc { |order| order.to_s } } ]

    when "bulk_coop_packing_sheets"

      header = ["Customer", "Product", "Variant", "Sum Total"]

      columns = [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| lis.first.variant.full_name },
        proc { |lis|  lis.sum { |li| li.quantity } } ]

      rules = [ { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.full_name } },
        { group_by: proc { |li| li.order },
        sort_by: proc { |order| order.to_s } } ]

    when "bulk_coop_customer_payments"

      header = ["Customer", "Date of Order", "Total Cost", "Amount Owing", "Amount Paid"]

      columns = [ proc { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },
        proc { |lis| lis.first.order.completed_at.to_s },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.total } },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.outstanding_balance } },
        proc { |lis| lis.map { |li| li.order }.uniq.sum { |o| o.payment_total } } ]

      rules = [ { group_by: proc { |li| li.order },
        sort_by: proc { |order|  order.completed_at } } ]

    else # List all line items

      header = ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Units Required", "Remainder"]

      columns = [ proc { |lis| lis.first.variant.product.supplier.name },
        proc { |lis| lis.first.variant.product.name },
        proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
        proc { |lis| lis.first.variant.full_name },
        proc { |lis| lis.first.variant.weight || 0 },
        proc { |lis|  lis.sum { |li| li.quantity } },
        proc { |lis| lis.sum { |li| li.max_quantity || 0 } },
        proc { |lis| "" },
        proc { |lis| "" } ]

      rules = [ { group_by: proc { |li| li.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |li| li.variant.product },
        sort_by: proc { |product| product.name },
        summary_columns: [ proc { |lis| lis.first.variant.product.supplier.name },
          proc { |lis| lis.first.variant.product.name },
          proc { |lis| lis.first.variant.product.group_buy ? (lis.first.variant.product.group_buy_unit_size || 0.0) : "" },
          proc { |lis| "" },
          proc { |lis| "" },
          proc { |lis| lis.sum { |li| li.quantity * (li.variant.weight || 0) } },
          proc { |lis| lis.sum { |li| (li.max_quantity || 0) * (li.variant.weight || 0) } },
          proc { |lis| ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor },
          proc { |lis| lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } - ( ( (lis.first.variant.product.group_buy_unit_size || 0).zero? ? 0 : ( lis.sum { |li| ( [li.max_quantity || 0, li.quantity || 0].max ) * (li.variant.weight || 0) } / lis.first.variant.product.group_buy_unit_size ) ).floor * (lis.first.variant.product.group_buy_unit_size || 0) ) } ] },
        { group_by: proc { |li| li.variant },
        sort_by: proc { |variant| variant.full_name } } ]

    end

    order_grouper = OpenFoodNetwork::OrderGrouper.new rules, columns

    @header = header
    @table = order_grouper.table(@line_items)
    csv_file_name = "bulk_coop.csv"

    render_report(@header, @table, params[:csv], csv_file_name)
  end

  def payments
    params[:q] = {} unless params[:q]

    if params[:q][:completed_at_gt].blank?
      params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:completed_at_lt].blank?
      params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
    end
    params[:q][:meta_sort] ||= "completed_at.desc"

    @search = Spree::Order.complete.not_state(:canceled).managed_by(spree_current_user).search(params[:q])

    orders = @search.result
    payments = orders.map { |o| o.payments.select { |payment| payment.completed? } }.flatten # Only select completed payments

    @distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    @report_type = params[:report_type]

    case params[:report_type]
    when "payments_by_payment_type"
      table_items = payments

      header = ["Payment State", "Distributor", "Payment Type", "Total ($)"]

      columns = [ proc { |payments| payments.first.order.payment_state },
        proc { |payments| payments.first.order.distributor.name },
        proc { |payments| payments.first.payment_method.name },
        proc { |payments| payments.sum { |payment| payment.amount } } ]

      rules = [ { group_by: proc { |payment| payment.order.payment_state },
        sort_by: proc { |payment_state| payment_state } },
        { group_by: proc { |payment| payment.order.distributor },
        sort_by: proc { |distributor| distributor.name } },
        { group_by: proc { |payment| payment.payment_method },
        sort_by: proc { |method| method.name } } ]

    when "itemised_payment_totals"
      table_items = orders

      header = ["Payment State", "Distributor", "Product Total ($)", "Shipping Total ($)", "Outstanding Balance ($)", "Total ($)"]

      columns = [ proc { |orders| orders.first.payment_state },
        proc { |orders| orders.first.distributor.name },
        proc { |orders| orders.sum { |o| o.item_total } },
        proc { |orders| orders.sum { |o| o.ship_total } },
        proc { |orders| orders.sum { |o| o.outstanding_balance } },
        proc { |orders| orders.sum { |o| o.total } } ]

      rules = [ { group_by: proc { |order| order.payment_state },
        sort_by: proc { |payment_state| payment_state } },
        { group_by: proc { |order| order.distributor },
        sort_by: proc { |distributor| distributor.name } } ]

    when "payment_totals"
      table_items = orders

      header = ["Payment State", "Distributor", "Product Total ($)", "Shipping Total ($)", "Total ($)", "EFT ($)", "PayPal ($)", "Outstanding Balance ($)"]

      columns = [ proc { |orders| orders.first.payment_state },
        proc { |orders| orders.first.distributor.name },
        proc { |orders| orders.sum { |o| o.item_total } },
        proc { |orders| orders.sum { |o| o.ship_total } },
        proc { |orders| orders.sum { |o| o.total } },
        proc { |orders| orders.sum { |o| o.payments.select { |payment| payment.completed? && (payment.payment_method.name.to_s.include? "EFT") }.sum { |payment| payment.amount } } },
        proc { |orders| orders.sum { |o| o.payments.select { |payment| payment.completed? && (payment.payment_method.name.to_s.include? "PayPal") }.sum{ |payment| payment.amount } } },
        proc { |orders| orders.sum { |o| o.outstanding_balance } } ]

      rules = [ { group_by: proc { |order| order.payment_state },
        sort_by: proc { |payment_state| payment_state } },
        { group_by: proc { |order| order.distributor },
        sort_by: proc { |distributor| distributor.name } } ]

    else
      table_items = payments

      header = ["Payment State", "Distributor", "Payment Type", "Total ($)"]

      columns = [ proc { |payments| payments.first.order.payment_state },
        proc { |payments| payments.first.order.distributor.name },
        proc { |payments| payments.first.payment_method.name },
        proc { |payments| payments.sum { |payment| payment.amount } } ]

      rules = [ { group_by: proc { |payment| payment.order.payment_state },
        sort_by: proc { |payment_state| payment_state } },
        { group_by: proc { |payment| payment.order.distributor },
        sort_by: proc { |distributor| distributor.name } },
        { group_by: proc { |payment| payment.payment_method },
        sort_by: proc { |method| method.name } } ]

    end

    order_grouper = OpenFoodNetwork::OrderGrouper.new rules, columns

    @header = header
    @table = order_grouper.table(table_items)
    csv_file_name = "payments.csv"

    render_report(@header, @table, params[:csv], csv_file_name)

  end

  def orders_and_fulfillment
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

    # -- Search
    @search = Spree::Order.complete.not_state(:canceled).managed_by(spree_current_user).search(params[:q])
    orders = @search.result
    @line_items = orders.map do |o|
      lis = o.line_items.managed_by(spree_current_user)
      lis = lis.supplied_by_any(params[:supplier_id_in]) if params[:supplier_id_in].present?
      lis
    end.flatten
    #payments = orders.map { |o| o.payments.select { |payment| payment.completed? } }.flatten # Only select completed payments

    # -- Prepare form options
    my_distributors = Enterprise.is_distributor.managed_by(spree_current_user)
    my_suppliers = Enterprise.is_primary_producer.managed_by(spree_current_user)

    # My distributors and any distributors distributing products I supply
    @distributors = my_distributors | Enterprise.with_distributed_products_outer.merge(Spree::Product.in_any_supplier(my_suppliers))

    # My suppliers and any suppliers supplying products I distribute
    @suppliers = my_suppliers | my_distributors.map { |d| Spree::Product.in_distributor(d) }.flatten.map(&:supplier).uniq

    @order_cycles = OrderCycle.active_or_complete.accessible_by(spree_current_user).order('orders_close_at DESC')
    @report_types = REPORT_TYPES[:orders_and_fulfillment]
    @report_type = params[:report_type]

    # -- Format according to report type
    case params[:report_type]
    when "order_cycle_supplier_totals"
      table_items = @line_items
      @include_blank = 'All'

      header = ["Producer", "Product", "Variant", "Amount", "Total Units", "Curr. Cost per Unit", "Total Cost", "Status", "Incoming Transport"]

      columns = [ proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.full_name },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| total_units(line_items) },
        proc { |line_items| line_items.first.variant.price },
        proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
        proc { |line_items| "" },
        proc { |line_items| "incoming transport" } ]

        rules = [ { group_by: proc { |line_item| line_item.variant.product.supplier },
          sort_by: proc { |supplier| supplier.name } },
          { group_by: proc { |line_item| line_item.variant.product },
          sort_by: proc { |product| product.name } },
          { group_by: proc { |line_item| line_item.variant },
          sort_by: proc { |variant| variant.full_name } } ]

    when "order_cycle_supplier_totals_by_distributor"
      table_items = @line_items
      @include_blank = 'All'

      header = ["Producer", "Product", "Variant", "To Hub", "Amount", "Curr. Cost per Unit", "Total Cost", "Shipping Method"]

      columns = [ proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.full_name },
        proc { |line_items| line_items.first.order.distributor.name },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.first.variant.price },
        proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
        proc { |line_items| "shipping method" } ]

      rules = [ { group_by: proc { |line_item| line_item.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |line_item| line_item.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |line_item| line_item.variant },
        sort_by: proc { |variant| variant.full_name },
        summary_columns: [ proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| "TOTAL" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
          proc { |line_items| "" } ] },
        { group_by: proc { |line_item| line_item.order.distributor },
        sort_by: proc { |distributor| distributor.name } } ]

    when "order_cycle_distributor_totals_by_supplier"
      table_items = @line_items
      @include_blank = 'All'

      header = ["Hub", "Producer", "Product", "Variant", "Amount", "Curr. Cost per Unit", "Total Cost", "Total Shipping Cost", "Shipping Method"]

      columns = [ proc { |line_items| line_items.first.order.distributor.name },
        proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.full_name },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.first.variant.price },
        proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
        proc { |line_items| "" },
        proc { |line_items| "shipping method" } ]

      rules = [ { group_by: proc { |line_item| line_item.order.distributor },
        sort_by: proc { |distributor| distributor.name },
        summary_columns: [ proc { |line_items| "" },
          proc { |line_items| "TOTAL" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| "" },
          proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
          proc { |line_items| line_items.map { |li| li.order }.uniq.sum { |o| o.ship_total } },
          proc { |line_items| "" } ] },
        { group_by: proc { |line_item| line_item.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |line_item| line_item.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |line_item| line_item.variant },
        sort_by: proc { |variant| variant.full_name } } ]

    when "order_cycle_customer_totals"
      table_items = @line_items
      @include_blank = 'All'

      header = ["Hub", "Customer", "Email", "Phone", "Producer", "Product", "Variant", "Amount", "Item ($)", "Dist ($)", "Ship ($)", "Total ($)", "Paid?",
                "Shipping", "Delivery?", "Ship street", "Ship street 2", "Ship city", "Ship postcode", "Ship state", "Order notes"]

      rsa = proc { |line_items| line_items.first.order.shipping_method.andand.require_ship_address }

      columns = [ proc { |line_items| line_items.first.order.distributor.name },
        proc { |line_items| line_items.first.order.bill_address.firstname + " " + line_items.first.order.bill_address.lastname },
        proc { |line_items| line_items.first.order.email },
        proc { |line_items| line_items.first.order.bill_address.phone },
        proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.full_name },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },

        proc { |line_items| line_items.first.order.shipping_method.andand.name },
        proc { |line_items| rsa.call(line_items) ? 'Y' : 'N' },
        proc { |line_items| line_items.first.order.ship_address.andand.address1 if rsa.call(line_items) },
        proc { |line_items| line_items.first.order.ship_address.andand.address2 if rsa.call(line_items) },
        proc { |line_items| line_items.first.order.ship_address.andand.city if rsa.call(line_items) },
        proc { |line_items| line_items.first.order.ship_address.andand.zipcode if rsa.call(line_items) },
        proc { |line_items| line_items.first.order.ship_address.andand.state if rsa.call(line_items) },

        proc { |line_items| line_items.first.order.special_instructions }]

    rules = [ { group_by: proc { |line_item| line_item.order.distributor },
      sort_by: proc { |distributor| distributor.name } },
      { group_by: proc { |line_item| line_item.order },
      sort_by: proc { |order| order.bill_address.lastname + " " + order.bill_address.firstname },
      summary_columns: [ proc { |line_items| line_items.first.order.distributor.name },
        proc { |line_items| line_items.first.order.bill_address.firstname + " " + line_items.first.order.bill_address.lastname },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "TOTAL" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
        proc { |line_items| line_items.map { |li| li.order }.uniq.sum { |o| o.distribution_total } },
        proc { |line_items| line_items.map { |li| li.order }.uniq.sum { |o| o.ship_total } },
        proc { |line_items| line_items.map { |li| li.order }.uniq.sum { |o| o.total } },
        proc { |line_items| line_items.all? { |li| li.order.paid? } ? "Yes" : "No" },

        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },
        proc { |line_items| "" },

        proc { |line_items| "" } ] },

      { group_by: proc { |line_item| line_item.variant.product },
      sort_by: proc { |product| product.name } },
      { group_by: proc { |line_item| line_item.variant },
       sort_by: proc { |variant| variant.full_name } } ]

    else
      table_items = @line_items
      @include_blank = 'All'

      header = ["Producer", "Product", "Variant", "Amount", "Curr. Cost per Unit", "Total Cost", "Status", "Incoming Transport"]

      columns = [ proc { |line_items| line_items.first.variant.product.supplier.name },
        proc { |line_items| line_items.first.variant.product.name },
        proc { |line_items| line_items.first.variant.full_name },
        proc { |line_items| line_items.sum { |li| li.quantity } },
        proc { |line_items| line_items.first.variant.price },
        proc { |line_items| line_items.sum { |li| li.quantity * li.price } },
        proc { |line_items| "" },
        proc { |line_items| "incoming transport" } ]

      rules = [ { group_by: proc { |line_item| line_item.variant.product.supplier },
        sort_by: proc { |supplier| supplier.name } },
        { group_by: proc { |line_item| line_item.variant.product },
        sort_by: proc { |product| product.name } },
        { group_by: proc { |line_item| line_item.variant },
        sort_by: proc { |variant| variant.full_name } } ]

    end

    order_grouper = OpenFoodNetwork::OrderGrouper.new rules, columns

    @header = header
    @table = order_grouper.table(table_items)
    csv_file_name = "#{__method__}.csv"

    render_report(@header, @table, params[:csv], csv_file_name)

  end

  def products_and_inventory
    @report_types = REPORT_TYPES[:products_and_inventory]

    @report = OpenFoodNetwork::ProductsAndInventoryReport.new spree_current_user, params
    #@table = @report.table
    #@header = @report.header
    render_report(@report.header, @report.table, params[:csv], "products_and_inventory.csv")
  end

  def render_report (header, table, create_csv, csv_file_name)
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
      :users_and_enterprises => { :name => "Users & Enterprises", :description => "Enterprise Ownership & Status" }
    }
    # Return only reports the user is authorized to view.
    reports.select { |action| can? action, :report }
  end

  def total_units(line_items)
    return " " if line_items.map{ |li| li.variant.unit_value.nil? }.any?
    total_units = line_items.sum do |li|
      scale_factor = ( li.product.variant_unit == 'weight' ? 1000 : 1 )
      li.quantity * li.variant.unit_value / scale_factor
    end
    total_units.round(3)
  end
end
