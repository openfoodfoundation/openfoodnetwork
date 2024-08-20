# frozen_string_literal: true

module Reporting
  module Reports
    module XeroInvoices
      class Base < ReportTemplate
        def xero_columns
          # These are NOT to be translated, they need to be in this exact format to work with Xero
          %w(*ContactName EmailAddress POAddressLine1 POAddressLine2 POAddressLine3 POAddressLine4
             POCity PORegion POPostalCode POCountry *InvoiceNumber Reference *InvoiceDate *DueDate
             InventoryItemCode *Description *Quantity *UnitAmount Discount *AccountCode *TaxType
             TrackingName1 TrackingOption1 TrackingName2 TrackingOption2 Currency
             BrandingTheme Paid?)
        end

        def custom_headers
          xero_columns.index_by(&:to_sym)
        end

        # This report calculate data in a specific way, so instead of refactoring it
        # we just encapsulate the result in the columns method
        def columns
          result = {}
          xero_columns.each_with_index do |header, id|
            result[header.to_sym] = proc { |row| row[id] }
          end
          result
        end

        def default_params
          {
            report_subtype: 'summary',
            invoice_date: Time.zone.today,
            due_date: Time.zone.today + 1.month,
            account_code: 'food sales'
          }
        end

        def search
          permissions = ::Permissions::Order.new(@user)
          permissions.editable_orders.complete.not_state(:canceled).ransack(ransack_params)
        end

        # In the new way of managing reports, query_result should be an ActiveRecordRelation
        # Here we directly transform the ActiveRecordRelation into table_rows without using the
        # new ReportGrouper, so we can keep the old report without refactoring it
        def query_result
          search_result = search.result.reorder('id DESC')

          rows = []

          search_result.each_with_index do |order, i|
            invoice_number = invoice_number_for(order, i)
            rows += detail_rows_for_order(order, invoice_number, params) if detail?
            rows += summary_rows_for_order(order, invoice_number, params)
          end

          rows.compact
        end

        private

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
          [summary_row(order, I18n.t(:report_header_total_untaxable_produce),
                       total_untaxable_products(order), invoice_number,
                       I18n.t(:report_header_gst_free_income), opts),
           summary_row(order, I18n.t(:report_header_total_taxable_produce),
                       total_taxable_products(order), invoice_number,
                       I18n.t(:report_header_gst_on_income), opts)]
        end

        def fee_summary_rows(order, invoice_number, opts)
          [summary_row(order, I18n.t(:report_header_total_untaxable_fees),
                       total_untaxable_fees(order), invoice_number,
                       I18n.t(:report_header_gst_free_income), opts),
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
          [summary_row(order, I18n.t(:report_header_total_untaxable_admin),
                       total_untaxable_admin_adjustments(order), invoice_number,
                       I18n.t(:report_header_gst_free_income), opts),
           summary_row(order, I18n.t(:report_header_total_taxable_admin),
                       total_taxable_admin_adjustments(order), invoice_number,
                       I18n.t(:report_header_gst_on_income), opts)]
        end

        def summary_row(order, description, amount, invoice_number, tax_type, opts = {})
          row order, '', description, '1', amount, invoice_number, tax_type, opts
        end

        # rubocop:disable Metrics/AbcSize
        def row(order, sku, description, quantity, amount, invoice_number, tax_type, opts = {})
          return nil if amount == 0

          [order.bill_address&.full_name,
           order.email,
           order.bill_address&.address1,
           order.bill_address&.address2,
           '',
           '',
           order.bill_address&.city,
           order.bill_address&.state.to_s,
           order.bill_address&.zipcode,
           order.bill_address&.country&.name,
           invoice_number,
           order.number,
           opts[:invoice_date].to_date.to_s,
           opts[:due_date].to_date.to_s,
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
           CurrentConfig.get(:currency),
           '',
           order.paid? ? I18n.t(:y) : I18n.t(:n)]
        end
        # rubocop:enable Metrics/AbcSize

        def admin_adjustments(order)
          order.adjustments.admin
        end

        def adjustment_order(adjustment)
          adjustment.adjustable.is_a?(Spree::Order) ? adjustment.adjustable : nil
        end

        def invoice_number_for(order, idx)
          if params[:initial_invoice_number].present?
            params[:initial_invoice_number].to_i + idx
          else
            order.number
          end
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
          tax_on_shipping = order.shipments
            .sum("additional_tax_total + included_tax_total").positive?
          if tax_on_shipping
            I18n.t(:report_header_gst_on_income)
          else
            I18n.t(:report_header_gst_free_income)
          end
        end

        def total_untaxable_admin_adjustments(order)
          order.adjustments.admin.where(tax_category: nil).sum(:amount)
        end

        def total_taxable_admin_adjustments(order)
          order.adjustments.admin.where.not(tax_category: nil).sum(:amount)
        end

        def detail?
          params[:report_subtype] == 'detailed'
        end

        def tax_type(taxable)
          if taxable.has_tax?
            I18n.t(:report_header_gst_on_income)
          else
            I18n.t(:report_header_gst_free_income)
          end
        end
      end
    end
  end
end
