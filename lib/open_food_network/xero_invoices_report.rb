# frozen_string_literal: true

module OpenFoodNetwork
  class XeroInvoicesReport
    def initialize(user, opts = {}, compile_table = false)
      @user = user

      @opts = opts.
        symbolize_keys.
        reject { |_k, v| v.blank? }.
        reverse_merge( report_type: 'summary',
                       invoice_date: Time.zone.today,
                       due_date: Time.zone.today + 1.month,
                       account_code: 'food sales' )
      @compile_table = compile_table
    end

    def header
      # NOTE: These are NOT to be translated, they need to be in this exact format to work with Xero
      %w(*ContactName EmailAddress POAddressLine1 POAddressLine2 POAddressLine3 POAddressLine4
         POCity PORegion POPostalCode POCountry *InvoiceNumber Reference *InvoiceDate *DueDate InventoryItemCode *Description *Quantity *UnitAmount Discount *AccountCode *TaxType TrackingName1 TrackingOption1 TrackingName2 TrackingOption2 Currency BrandingTheme Paid?)
    end

    def search
      permissions = ::Permissions::Order.new(@user)
      permissions.editable_orders.complete.not_state(:canceled).ransack(@opts[:q])
    end

    def orders
      search.result.reorder('id DESC')
    end

    def table
      return [] unless @compile_table

      rows = []

      orders.each_with_index do |order, i|
        invoice_number = invoice_number_for(order, i)
        rows += detail_rows_for_order(order, invoice_number, @opts) if detail?
        rows += summary_rows_for_order(order, invoice_number, @opts)
      end

      rows.compact
    end

    private

    def report_options
      @opts.merge(line_item_includes: line_item_includes)
    end

    def line_item_includes
      [:bill_address, :adjustments,
       { line_items: { variant: [{ option_values: :option_type }, { product: :supplier }] } }]
    end

    def detail_rows_for_order(order, invoice_number, opts)
      rows = []

      rows += line_item_detail_rows(order, invoice_number, opts)
      rows += adjustment_detail_rows(order, invoice_number, opts)

      rows
    end

    def line_item_detail_rows(order, invoice_number, opts)
      order.line_items.map do |line_item|
        line_item_detail_row(line_item, invoice_number, opts)
      end
    end

    def line_item_detail_row(line_item, invoice_number, opts)
      row(line_item.order,
          line_item.variant.sku,
          line_item.product_and_full_name,
          line_item.quantity.to_s,
          line_item.price.to_s,
          invoice_number,
          tax_type(line_item),
          opts)
    end

    def adjustment_detail_rows(order, invoice_number, opts)
      admin_adjustments(order).map do |adjustment|
        adjustment_detail_row(adjustment, invoice_number, opts)
      end
    end

    def adjustment_detail_row(adjustment, invoice_number, opts)
      row(adjustment_order(adjustment),
          '',
          adjustment.label,
          1,
          adjustment.amount,
          invoice_number,
          tax_type(adjustment),
          opts)
    end

    def summary_rows_for_order(order, invoice_number, opts)
      rows = []

      rows += produce_summary_rows(order, invoice_number, opts) unless detail?
      rows += fee_summary_rows(order, invoice_number, opts)
      rows += shipping_summary_rows(order, invoice_number, opts)
      rows += payment_summary_rows(order, invoice_number, opts)
      rows += admin_adjustment_summary_rows(order, invoice_number, opts) unless detail?

      rows
    end

    def produce_summary_rows(order, invoice_number, opts)
      [summary_row(order, I18n.t(:report_header_total_untaxable_produce), total_untaxable_products(order), invoice_number, I18n.t(:report_header_gst_free_income), opts),
       summary_row(order, I18n.t(:report_header_total_taxable_produce),
                   total_taxable_products(order), invoice_number, I18n.t(:report_header_gst_on_income), opts)]
    end

    def fee_summary_rows(order, invoice_number, opts)
      [summary_row(order, I18n.t(:report_header_total_untaxable_fees), total_untaxable_fees(order), invoice_number, I18n.t(:report_header_gst_free_income), opts),
       summary_row(order, I18n.t(:report_header_total_taxable_fees), total_taxable_fees(order),
                   invoice_number, I18n.t(:report_header_gst_on_income), opts)]
    end

    def shipping_summary_rows(order, invoice_number, opts)
      [summary_row(order, I18n.t(:report_header_delivery_shipping_cost), total_shipping(order),
                   invoice_number, tax_on_shipping_s(order), opts)]
    end

    def payment_summary_rows(order, invoice_number, opts)
      [summary_row(order, I18n.t(:report_header_transaction_fee), total_transaction(order),
                   invoice_number, I18n.t(:report_header_gst_free_income), opts)]
    end

    def admin_adjustment_summary_rows(order, invoice_number, opts)
      [summary_row(order, I18n.t(:report_header_total_untaxable_admin), total_untaxable_admin_adjustments(order), invoice_number, I18n.t(:report_header_gst_free_income), opts),
       summary_row(order, I18n.t(:report_header_total_taxable_admin),
                   total_taxable_admin_adjustments(order), invoice_number, I18n.t(:report_header_gst_on_income), opts)]
    end

    def summary_row(order, description, amount, invoice_number, tax_type, opts = {})
      row order, '', description, '1', amount, invoice_number, tax_type, opts
    end

    def row(order, sku, description, quantity, amount, invoice_number, tax_type, opts = {})
      # rubocop:disable Style/NumericPredicate
      return nil if amount == 0
      # rubocop:enable Style/NumericPredicate

      [order.bill_address.andand.full_name,
       order.email,
       order.bill_address.andand.address1,
       order.bill_address.andand.address2,
       '',
       '',
       order.bill_address.andand.city,
       order.bill_address.andand.state,
       order.bill_address.andand.zipcode,
       order.bill_address.andand.country.andand.name,
       invoice_number,
       order.number,
       opts[:invoice_date],
       opts[:due_date],
       sku,
       description,
       quantity,
       amount,
       '',
       opts[:account_code],
       tax_type,
       '',
       '',
       '',
       '',
       Spree::Config.currency,
       '',
       order.paid? ? I18n.t(:y) : I18n.t(:n)]
    end

    def admin_adjustments(order)
      order.adjustments.admin
    end

    def adjustment_order(adjustment)
      adjustment.adjustable.is_a?(Spree::Order) ? adjustment.adjustable : nil
    end

    def invoice_number_for(order, idx)
      @opts[:initial_invoice_number] ? @opts[:initial_invoice_number].to_i + idx : order.number
    end

    def total_untaxable_products(order)
      order.line_items.without_tax.to_a.sum(&:amount)
    end

    def total_taxable_products(order)
      order.line_items.with_tax.to_a.sum(&:amount)
    end

    def total_untaxable_fees(order)
      order.all_adjustments.enterprise_fee.where(tax_category: nil).sum(:amount)
    end

    def total_taxable_fees(order)
      order.all_adjustments.enterprise_fee.where.not(tax_category: nil).sum(:amount)
    end

    def total_shipping(order)
      order.all_adjustments.shipping.sum(:amount)
    end

    def total_transaction(order)
      order.all_adjustments.payment_fee.sum(:amount)
    end

    def tax_on_shipping_s(order)
      tax_on_shipping = order.shipments.sum("additional_tax_total + included_tax_total").positive?
      tax_on_shipping ? I18n.t(:report_header_gst_on_income) : I18n.t(:report_header_gst_free_income)
    end

    def total_untaxable_admin_adjustments(order)
      order.adjustments.admin.where(tax_category: nil).sum(:amount)
    end

    def total_taxable_admin_adjustments(order)
      order.adjustments.admin.where.not(tax_category: nil).sum(:amount)
    end

    def detail?
      @opts[:report_type] == 'detailed'
    end

    def tax_type(taxable)
      taxable.has_tax? ? I18n.t(:report_header_gst_on_income) : I18n.t(:report_header_gst_free_income)
    end
  end
end
