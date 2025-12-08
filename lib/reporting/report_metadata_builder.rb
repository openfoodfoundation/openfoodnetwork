# frozen_string_literal: true

module Reporting
  class ReportMetadataBuilder
    attr_reader :report, :current_user

    def initialize(report, current_user = nil)
      @report = report
      @current_user = current_user
    end

    def rows
      rows = []
      rows.concat(title_rows)
      rows.concat(date_range_rows)
      rows.concat(printed_rows)
      rows << [] if rows.any? # spacer only if something was added
      rows
    end

    private

    DATE_FROM_KEYS = %i[completed_at_gt created_at_gt updated_at_gt].freeze
    DATE_TO_KEYS   = %i[completed_at_lt created_at_lt updated_at_lt].freeze

    def title_rows
      type = params[:report_type]
      sub  = params[:report_subtype]
      return [] if type.blank?

      label     = I18n.t("admin.reports.metadata.report_title", default: "Report Title")
      type_name = I18n.t("admin.reports.#{type}.name",
                         default: I18n.t("admin.reports.#{type}",
                                         default: type.to_s.tr('_', ' ').titleize))

      sub_name = sub.present? ? sub.to_s.tr('_', ' ').titleize : nil

      title = [type_name, sub_name].compact.join(' - ')
      [[label, title]]
    end

    def date_range_rows
      q = indifferent_ransack
      from = first_present(q, DATE_FROM_KEYS)
      to   = first_present(q, DATE_TO_KEYS)
      return [] unless from || to

      label = I18n.t("date_range", default: "Date Range")
      [[label, [from, to].compact.join(' - ')]] # en dash
    end

    def first_present(hash, keys)
      keys.map { |k| hash[k] }.find(&:present?)
    end

    def indifferent_ransack
      (report.ransack_params || {}).with_indifferent_access
    end

    def printed_rows
      [[I18n.t("printed", default: "Printed"), Time.now.utc.strftime('%F %T %Z')]]
    end

    def params
      (report.params || {}).with_indifferent_access
    end
  end
end
