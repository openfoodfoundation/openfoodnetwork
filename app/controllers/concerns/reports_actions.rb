# frozen_string_literal: true

module ReportsActions
  extend ActiveSupport::Concern

  def reports
    Reporting::Reports::List.all
  end

  private

  def authorize_report
    authorize! report_type.to_sym, :report
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

  def report_subtypes
    reports[report_type.to_sym] || []
  end

  def report_subtypes_codes
    report_subtypes.map(&:second).map(&:to_s)
  end

  def report_subtype
    params[:report_subtype] || report_subtypes_codes.first
  end

  def ransack_params
    raw_params[:q]
  end

  def report_format
    params[:report_format]
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
