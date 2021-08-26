# frozen_string_literal: true

module ReportsActions
  extend ActiveSupport::Concern

  private

  def authorize_report
    authorize! report_type&.to_sym, :report
  end

  def report_class
    return if report_type.blank?

    report_loader.report_class
  end

  def report_loader
    @report_loader ||= ::Reporting::ReportLoader.new(report_type, report_subtype)
  end

  def report_type
    params[:report_type]
  end

  def report_subtype
    params[:report_subtype]
  end

  def ransack_params
    raw_params[:q]
  end

  def report_options
    raw_params[:options]
  end

  def report_format
    params[:report_format]
  end

  def export_spreadsheet?
    ['xlsx', 'ods', 'csv'].include?(report_format)
  end

  def form_options_required?
    [:packing, :customers, :products_and_inventory, :order_cycle_management].
      include? report_type.to_sym
  end

  def report_filename
    "#{report_type || action_name}_#{file_timestamp}.#{report_format}"
  end

  def file_timestamp
    Time.zone.now.strftime("%Y%m%d")
  end

  def i18n_scope
    'admin.reports'
  end
end
