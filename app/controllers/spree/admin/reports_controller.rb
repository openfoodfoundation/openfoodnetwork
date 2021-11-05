# frozen_string_literal: true

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
require 'open_food_network/sales_tax_report'
require 'open_food_network/xero_invoices_report'
require 'open_food_network/payments_report'
require 'open_food_network/orders_and_fulfillments_report'

module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController
      include Spree::ReportsHelper
      helper ::ReportsHelper

      ORDER_MANAGEMENT_ENGINE_REPORTS = [
        :bulk_coop,
        :enterprise_fee_summary
      ].freeze

      helper_method :render_content?

      before_action :cache_search_state
      # Fetches user's distributors, suppliers and order_cycles
      before_action :load_basic_data, only: [:customers, :products_and_inventory, :order_cycle_management]
      before_action :load_associated_data, only: [:orders_and_fulfillment]

      respond_to :html

      def report_types
        OpenFoodNetwork::Reports::List.all
      end

      def index
        @reports = authorized_reports
        respond_with(@reports)
      end

      def customers
        @report_types = report_types[:customers]
        @report_type = params[:report_type]
        @report = OpenFoodNetwork::CustomersReport.new spree_current_user, raw_params,
                                                       render_content?
        render_report(@report.header, @report.table, params[:csv], "customers_#{timestamp}.csv")
      end

      def order_cycle_management
        raw_params[:q] ||= {}

        @report_types = report_types[:order_cycle_management]
        @report_type = params[:report_type]

        # -- Build Report with Order Grouper
        @report = OpenFoodNetwork::OrderCycleManagementReport.new spree_current_user,
                                                                  raw_params,
                                                                  render_content?
        @table = @report.table_items

        render_report(@report.header, @table, params[:csv],
                      "order_cycle_management_#{timestamp}.csv")
      end

      def orders_and_distributors
        @report = OpenFoodNetwork::OrderAndDistributorReport.new spree_current_user,
                                                                 raw_params,
                                                                 render_content?
        @search = @report.search
        csv_file_name = "orders_and_distributors_#{timestamp}.csv"
        render_report(@report.header, @report.table, params[:csv], csv_file_name)
      end

      def sales_tax
        @distributors = my_distributors
        @report_type = params[:report_type]
        @report = OpenFoodNetwork::SalesTaxReport.new spree_current_user, raw_params,
                                                      render_content?
        render_report(@report.header, @report.table, params[:csv], "sales_tax.csv")
      end

      def payments
        # -- Prepare Form Options
        @distributors = my_distributors
        @report_type = params[:report_type]

        # -- Build Report with Order Grouper
        @report = OpenFoodNetwork::PaymentsReport.new spree_current_user, raw_params,
                                                      render_content?
        @table = order_grouper_table
        csv_file_name = "payments_#{timestamp}.csv"

        render_report(@report.header, @table, params[:csv], csv_file_name)
      end

      def orders_and_fulfillment
        raw_params[:q] ||= orders_and_fulfillment_default_filters

        @report_types = report_types[:orders_and_fulfillment]
        @report_type = params[:report_type]

        @include_blank = I18n.t(:all)

        # -- Build Report with Order Grouper
        @report = OpenFoodNetwork::OrdersAndFulfillmentsReport.new spree_current_user,
                                                                   raw_params,
                                                                   render_content?
        @table = order_grouper_table
        csv_file_name = "#{params[:report_type]}_#{timestamp}.csv"

        render_report(@report.header, @table, params[:csv], csv_file_name)
      end

      def products_and_inventory
        @report_types = report_types[:products_and_inventory]
        @report = if params[:report_type] != 'lettuce_share'
                    OpenFoodNetwork::ProductsAndInventoryReport.new spree_current_user,
                                                                    raw_params,
                                                                    render_content?
                  else
                    OpenFoodNetwork::LettuceShareReport.new spree_current_user,
                                                            raw_params,
                                                            render_content?
                  end

        render_report @report.header,
                      @report.table,
                      params[:csv],
                      "products_and_inventory_#{timestamp}.csv"
      end

      def users_and_enterprises
        @report = OpenFoodNetwork::UsersAndEnterprisesReport.new raw_params, render_content?
        render_report(@report.header, @report.table, params[:csv],
                      "users_and_enterprises_#{timestamp}.csv")
      end

      def xero_invoices
        raw_params[:q] ||= {}

        @distributors = my_distributors
        @order_cycles = my_order_cycles

        @report = OpenFoodNetwork::XeroInvoicesReport.new(spree_current_user,
                                                          raw_params,
                                                          render_content?)
        render_report(@report.header, @report.table, params[:csv], "xero_invoices_#{timestamp}.csv")
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

      def render_report(header, table, create_csv, csv_file_name)
        send_data csv_report(header, table), filename: csv_file_name if create_csv
        @header = header
        @table = table
        # Rendering HTML is the default.
      end

      def load_associated_data
        form_options = Reporting::FrontendData.new(spree_current_user)

        @distributors = form_options.distributors
        @suppliers = form_options.suppliers
        @order_cycles = form_options.order_cycles
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

      def orders_and_fulfillment_default_filters
        now = Time.zone.now
        { completed_at_gt: (now - 1.month).beginning_of_day,
          completed_at_lt: (now + 1.day).beginning_of_day }
      end
    end
  end
end
