# frozen_string_literal: true

module Reporting
  class ReportMetadataBuilder
    attr_reader :report, :current_user

    # Mirror ReportHeadersBuilder signature for consistency
    def initialize(report, current_user = nil)
      @report = report
      @current_user = current_user
    end

    # Public API used by ReportRenderer
    def rows
      return [] unless include_metadata?

      rows = []
      rows += title_rows
      rows += date_range_rows
      rows += printed_rows
      rows += other_filter_rows
      rows << [] # spacer before the sheet
      rows
    end

    private

    def title_rows
      type = params[:report_type]
      sub  = params[:report_subtype]
      return [] unless present?(type)

      title = [type, sub].compact.map { |s| s.to_s.tr('_', ' ').titleize }.join(' – ')
      [['Report Title', title]]
    end

    def date_range_rows
      q = (report.ransack_params || {}).with_indifferent_access
      from = q[:completed_at_gt] || q[:created_at_gt] || q[:updated_at_gt]
      to   = q[:completed_at_lt] || q[:created_at_lt] || q[:updated_at_lt]
      return [] unless from || to

      [['Date range', [from, to].compact.join(' – ')]]
    end

    def printed_rows
      tz = defined?(Time.zone) && Time.zone ? Time.zone : Time
      [['Printed', tz.now.strftime('%Y-%m-%d %H:%M:%S %Z')]]
    end

    def other_filter_rows
      q = (report.ransack_params || {}).with_indifferent_access
      %i[
        completed_at_gt completed_at_lt
        created_at_gt created_at_lt
        updated_at_gt updated_at_lt
      ].each { |k| q.delete(k) }

      q.each_with_object([]) do |(k, v), rows|
        next unless present?(v)
        rows << [k.to_s.humanize, v.is_a?(Array) ? v.join(', ') : v.to_s]
      end
    end

    def params
      report.params || {}
    end

    def include_metadata?
      # Matches your previous guard (CSV/raw should not include metadata)
      params[:report_format].to_s != 'csv'
    end

    def present?(value)
      value.respond_to?(:present?) ? value.present? : !!value
    end
  end
end
