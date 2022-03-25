# frozen_string_literal: true

require 'csv'

require 'open_food_network/reports/list'
require 'open_food_network/orders_and_distributors_report'
require 'open_food_network/products_and_inventory_report'
require 'open_food_network/lettuce_share_report'
require 'open_food_network/group_buy_report'
require 'open_food_network/order_grouper'
require 'open_food_network/customers_report'
require 'open_food_network/users_and_enterprises_report'
require 'open_food_network/order_cycle_management_report'
require 'open_food_network/sales_tax_report'
require 'open_food_network/xero_invoices_report'
require 'open_food_network/payments_report'
require 'open_food_network/orders_and_fulfillment_report'

module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController
      include Spree::ReportsHelper
      include ReportsActions
      helper ::ReportsHelper

      ORDER_MANAGEMENT_ENGINE_REPORTS = [
        :bulk_coop,
        :enterprise_fee_summary
      ].freeze

      helper_method :render_content?

      before_action :cache_search_state
      # Fetches user's distributors, suppliers and order_cycles
      before_action :load_basic_data, only: [:customers, :products_and_inventory, :order_cycle_management]

      respond_to :html

      def report_types
        OpenFoodNetwork::Reports::List.all
      end

      def index
        @reports = authorized_reports
        respond_with(@reports)
      end

      def customers
        render_report2
      end

      def order_cycle_management
        render_report2
      end

      def orders_and_distributors
        render_report2
      end

      def sales_tax
        @distributors = my_distributors
        render_report2
      end

      def payments
        @distributors = my_distributors
        render_report2
      end

      def orders_and_fulfillment
        now = Time.zone.now
        raw_params[:q] ||= {
          completed_at_gt: (now - 1.month).beginning_of_day,
          completed_at_lt: (now + 1.day).beginning_of_day
        }

        form_options = Reporting::FrontendData.new(spree_current_user)

        @distributors = form_options.distributors
        @suppliers = form_options.suppliers
        @order_cycles = form_options.order_cycles

        @report_message = I18n.t("spree.admin.reports.customer_names_message.customer_names_tip")

        render_report2
      end

      def products_and_inventory
        render_report2
      end

      def users_and_enterprises
        render_report2
      end

      def xero_invoices
        @distributors = my_distributors
        @order_cycles = my_order_cycles

        render_report2
      end

      private

      def model_class
        Spree::Admin::ReportsController
      end

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
        @searching = search_keys.any? { |key| raw_params.key? key }
      end

      # We don't want to render data unless search params are supplied.
      # Compiling data can take a long time.
      def render_content?
        @searching
      end

      def render_report2
        @report_subtypes = report_types[action_name.to_sym]
        @report_subtype = params[:report_subtype]
        klass = "OpenFoodNetwork::#{action_name.camelize}Report".constantize
        @report = klass.new spree_current_user, raw_params, render_content?
        if report_format.present?
          data = Reporting::ReportRenderer.new(@report).public_send("to_#{report_format}")
          send_data data, filename: report_filename
        else
          @header = @report.table_headers
          @table = @report.table_rows

          render "show"
        end
      end

      def render_report(header, table, create_csv, csv_file_name)
        send_data csv_report(header, table), filename: csv_file_name if create_csv
        @header = header
        @table = table
      end

      def csv_report(header, table)
        CSV.generate do |csv|
          csv << header
          table.each { |row| csv << row }
        end
      end

      def load_basic_data
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
        supplier_ids = Spree::Product.in_distributors(distributors.select('enterprises.id')).
          select('spree_products.supplier_id')

        Enterprise.where(id: supplier_ids)
      end

      # Load order cycles the current user has access to
      def my_order_cycles
        OrderCycle.
          active_or_complete.
          visible_by(spree_current_user).
          order('orders_close_at DESC')
      end

      def order_grouper_table
        order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns, @report
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
        if report_in_order_management_engine?(report)
          main_app.public_send("new_order_management_reports_#{report}_url".to_sym)
        else
          spree.public_send("#{report}_admin_reports_url".to_sym)
        end
      rescue NoMethodError
        main_app.admin_reports_url(report_type: report)
      end

      # List of reports that have been moved to the Order Management engine
      def report_in_order_management_engine?(report)
        ORDER_MANAGEMENT_ENGINE_REPORTS.include?(report)
      end

      def timestamp
        Time.zone.now.strftime("%Y%m%d")
      end
    end
  end
end
