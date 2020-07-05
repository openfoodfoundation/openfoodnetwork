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

      report_loader.report_class
    end

    def report_loader
      @report_loader ||= Reports::ReportLoader.new(report_type, report_subtype)
    end

    def export_spreadsheet?
      ['xlsx', 'ods', 'csv'].include?(report_format)
    end

    def export_report
      render report_format.to_sym => @report.public_send("to_#{report_format}"),
             :filename => filename
    end

    def render_report
      assign_view_data
      load_form_options

      render "order_management/reports/#{report_type}"
    end

    def assign_view_data
      @report_type = report_type
      @report_subtype = report_subtype || report_loader.default_report_subtype
      @report_subtypes = report_class.report_subtypes.map do |subtype|
        [t("order_management.reports.packing.#{subtype}_report"), subtype]
      end
    end

    def load_form_options
      return unless form_options_required?

      form_options = Reports::FormOptionsLoader.new(spree_current_user)

      @distributors = form_options.distributors
      @suppliers = form_options.suppliers
      @order_cycles = form_options.order_cycles
    end

    def form_options_required?
      [:packing, :customers, :products_and_inventory, :order_cycle_management].
        include? report_type.to_sym
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
