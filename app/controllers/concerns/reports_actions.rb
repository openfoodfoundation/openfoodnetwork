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

  def report_title
    if report_subtype
      report_subtype_title
    else
      I18n.t(:name, scope: [:admin, :reports, report_type])
    end
  end

  def report_subtype_title
    report_subtypes.select { |_name, key| key.to_sym == report_subtype.to_sym }.first[0]
  end

  def ransack_params
    raw_params[:q]
  end

  def report_format
    params[:report_format].presence || "html"
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

  def rendering_options
    @rendering_options ||= ReportRenderingOptions.where(
      user: spree_current_user,
      report_type: report_type,
      report_subtype: report_subtype
    ).first_or_create do |report_rendering_options|
      report_rendering_options.options = {
        fields_to_show: if request.get?
                          @report.columns.keys -
                            @report.fields_to_hide
                        else
                          params[:fields_to_show]
                        end,
        display_summary_row: request.get?,
        display_header_row: false
      }
    end
    update_rendering_options
    @rendering_options
  end

  def update_rendering_options
    return unless request.post?

    @rendering_options.update(
      options: {
        fields_to_show: params[:fields_to_show],
        display_summary_row: params[:display_summary_row].present?,
        display_header_row: params[:display_header_row].present?
      }
    )
  end
end
