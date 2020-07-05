# frozen_string_literal: true

module OrderManagement
  class ReportsController < Spree::Admin::BaseController
    def show
      render_report && return if params[:q].blank?

      @report = report_class.new(spree_current_user, params[:q], params[:options])

      if export_spreadsheet?
        export_report
      else
        render_report
      end
    end

    private

    def report_type
      params[:report_type]
    end

    def report_subtype
      params[:report_subtype]
    end

    def report_class
      return if report_type.blank?

      "OrderManagement::Reports::#{report_class_type}#{report_class_subtype}".constantize
    end

    def report_class_type
      report_type.camelize
    end

    def report_class_subtype
      return unless report_subtype

      "::#{report_subtype.camelize}"
    end

    def export_spreadsheet?
      ['xlsx', 'ods', 'csv'].include?(report_format)
    end

    def export_report
      render report_format.to_sym => @report.public_send("to_#{report_format}"),
             :filename => filename
    end

    def render_report
      assign_report_options
      load_data_for_forms

      render "order_management/reports/#{report_type}"
    end

    def assign_report_options
      @report_type = report_type
      @report_subtypes = report_class.report_subtypes
      @report_subtype = report_subtype || @report_subtypes.first
    end

    def load_data_for_forms
      return unless ["packing"].include? report_type

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

    def my_order_cycles
      OrderCycle.
        active_or_complete.
        visible_by(spree_current_user).
        order('orders_close_at DESC')
    end

    def report_format
      params[:report_format]
    end

    def filename
      "#{params[:report_type] || action_name}_#{timestamp}.#{report_format}"
    end

    def timestamp
      Time.zone.now.strftime("%Y%m%d")
    end
  end
end
