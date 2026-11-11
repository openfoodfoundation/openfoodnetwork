# frozen_string_literal: true

module Api
  module V1
    class ReportParameters
      ID_KEYS = {
        "xero_invoices" => [:order_cycle_id_eq, :distributor_id_eq],
        "payments" => [:order_cycle_id_in, :distributor_id_eq],
        "sales_tax" => [:order_cycle_id_in, :distributor_id_eq],
        "packing" => [:order_cycle_id_in, :order_distributor_id_in]
      }.freeze

      SUBTYPE_ID_KEYS = {
        ["enterprise_fee_summary", "fee_summary"] =>
          [:order_cycle_ids, :distributor_ids]
      }.freeze

      DEFAULT_ID_KEYS = [:order_cycle_id_in, :distributor_id_in].freeze

      DATE_KEYS = {
        "packing" => {
          completed_at_gt: :order_completed_at_gt,
          completed_at_lt: :order_completed_at_lt
        }
      }.freeze

      DEFAULT_DATE_KEYS = {
        completed_at_gt: :completed_at_gt,
        completed_at_lt: :completed_at_lt
      }.freeze

      private_constant :ID_KEYS, :SUBTYPE_ID_KEYS, :DEFAULT_ID_KEYS,
                       :DATE_KEYS, :DEFAULT_DATE_KEYS

      # Captures the report selection and request parameters.
      def initialize(report_type, report_subtype, params)
        @report_type = report_type
        @report_subtype = report_subtype
        @params = params
      end

      # Returns the final report parameter hash with JSON output enabled.
      def to_h
        translated_params.merge(
          report_format: "json",
          report_subtype: @report_subtype
        )
      end

      private

      # Translates public filters into the shape expected by the selected report.
      def translated_params
        case @report_type
        when "customers"
          top_level_ids.merge(q: date_filters)
        when "products_and_inventory"
          top_level_ids
        when "order_cycle_management"
          { order_cycle_id: @params[:order_cycle_id] }.
            merge(translated_filter_params(nil, :distributor_id_in))
        else
          translated_filter_params(*query_id_keys)
        end
      end

      # Returns IDs that the report expects outside Ransack's q hash.
      def top_level_ids
        {
          order_cycle_id: @params[:order_cycle_id],
          distributor_id: @params[:distributor_id]
        }
      end

      # Resolves the Ransack ID keys for the report type and subtype.
      def query_id_keys
        SUBTYPE_ID_KEYS.fetch([@report_type, @report_subtype]) do
          ID_KEYS.fetch(@report_type, DEFAULT_ID_KEYS)
        end
      end

      # Builds the q hash with translated IDs and date filters.
      def translated_filter_params(cycle_key, distributor_key)
        filters = date_filters
        dates = filters.extract!(:completed_at_gt, :completed_at_lt)
        filters.merge!(id_filters(cycle_key, distributor_key))
        filters.merge!(translated_dates(dates))

        { q: filters }
      end

      # Adds only the supplied IDs using their report-specific Ransack keys.
      def id_filters(cycle_key, distributor_key)
        filters = {}

        if cycle_key && @params[:order_cycle_id].present?
          filters[cycle_key] = id_filter_value(cycle_key, @params[:order_cycle_id])
        end

        if distributor_key && @params[:distributor_id].present?
          filters[distributor_key] = id_filter_value(distributor_key, @params[:distributor_id])
        end

        filters
      end

      # Wraps IDs in arrays except for scalar _eq filters.
      def id_filter_value(key, value)
        key.to_s.end_with?("_eq") ? value : [value]
      end

      # Permits only the public completed-at date filters from q.
      def date_filters
        filters = @params[:q]
        return {} unless filters.respond_to?(:permit)

        filters.permit(:completed_at_gt, :completed_at_lt).to_h.symbolize_keys
      end

      # Maps public date keys to the report-specific date keys.
      def translated_dates(dates)
        DATE_KEYS.fetch(@report_type, DEFAULT_DATE_KEYS).filter_map do |source, target|
          [target, dates[source]] if dates[source].present?
        end.to_h
      end
    end
  end
end
