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

      def initialize(report_type, report_subtype, params)
        @report_type = report_type
        @report_subtype = report_subtype
        @params = params
      end

      def to_h
        translated_params.merge(
          report_format: "json",
          report_subtype: @report_subtype
        )
      end

      private

      def translated_params
        case @report_type
        when "customers"
          top_level_ids.merge(q: permitted_query_filters)
        when "products_and_inventory"
          top_level_ids
        when "order_cycle_management"
          { order_cycle_id: @params[:order_cycle_id] }.
            merge(translated_filter_params(nil, :distributor_id_in))
        else
          translated_filter_params(*query_id_keys)
        end
      end

      def top_level_ids
        {
          order_cycle_id: @params[:order_cycle_id],
          distributor_id: @params[:distributor_id]
        }
      end

      def query_id_keys
        SUBTYPE_ID_KEYS.fetch([@report_type, @report_subtype]) do
          ID_KEYS.fetch(@report_type, DEFAULT_ID_KEYS)
        end
      end

      def translated_filter_params(cycle_key, distributor_key)
        filters = permitted_query_filters
        dates = filters.extract!(:completed_at_gt, :completed_at_lt)
        filters.merge!(id_filters(cycle_key, distributor_key))
        filters.merge!(translated_dates(dates))

        { q: filters }
      end

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

      def id_filter_value(key, value)
        key.to_s.end_with?("_eq") ? value : [value]
      end

      def permitted_query_filters
        filters = @params[:q]
        filters.respond_to?(:to_h) ? filters.to_h.symbolize_keys : {}
      end

      # Explicit nil bounds prevent report defaults from adding a date window.
      def translated_dates(dates)
        DATE_KEYS.fetch(@report_type, DEFAULT_DATE_KEYS).to_h do |source, target|
          [target, dates[source].presence]
        end
      end
    end
  end
end
