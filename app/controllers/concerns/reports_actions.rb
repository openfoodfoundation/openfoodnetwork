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

  def report_subtype_title
    report_subtypes.select { |_name, key| key.to_sym == report_subtype.to_sym }.first[0]
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

  def render_options
    @render_options ||= ReportRenderingOptions.where(
      user: spree_current_user,
      report_type: report_type,
      report_subtype: report_subtype
    ).first_or_create do |new_instance|
      new_instance.options[:fields_to_show] = if @report.present?
                                                @report.columns.keys - @report.fields_to_hide
                                              else
                                                []
                                              end
      new_instance.options[:display_summary_row] = request.get? || params[:display_summary_row].present? 
    end
    if params[:fields_to_show].present?
      @render_options.options[:fields_to_show] = params[:fields_to_show]
    end
    @render_options.options[:display_summary_row] = params[:display_summary_row].present?
    @render_options.save
    @render_options
  end
end
