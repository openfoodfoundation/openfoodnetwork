# frozen_string_literal: true

module Api
  module V1
    class ReportParameters
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
          top_level_ids.merge(q: date_filters)
        when "products_and_inventory"
          top_level_ids
        when "order_cycle_management"
          {
            order_cycle_id: @params[:order_cycle_id],
            q: date_filters.merge(id_filters(nil, :distributor_id_in))
          }
        when "packing"
          packing_params
        else
          { q: date_filters.merge(id_filters(*query_id_keys)) }
        end
      end

      def top_level_ids
        {
          order_cycle_id: @params[:order_cycle_id],
          distributor_id: @params[:distributor_id]
        }
      end

      def query_id_keys
        if @report_type == "xero_invoices"
          [:order_cycle_id_eq, :distributor_id_eq]
        elsif @report_type == "enterprise_fee_summary" && @report_subtype == "fee_summary"
          [:order_cycle_ids, :distributor_ids]
        else
          [:order_cycle_id_in, :distributor_id_in]
        end
      end

      def id_filters(cycle_key, distributor_key)
        filters = {}

        if cycle_key && @params[:order_cycle_id].present?
          filters[cycle_key] = query_id_value(@params[:order_cycle_id])
        end

        if distributor_key && @params[:distributor_id].present?
          filters[distributor_key] = query_id_value(@params[:distributor_id])
        end

        filters
      end

      def query_id_value(value)
        @report_type == "xero_invoices" ? value : [value]
      end

      def date_filters
        @params.fetch(:q, ActionController::Parameters.new).
          permit(:completed_at_gt, :completed_at_lt).to_h.symbolize_keys
      end

      def packing_params
        filters = id_filters(:order_cycle_id_in, :order_distributor_id_in)
        dates = date_filters

        if dates[:completed_at_gt].present?
          filters[:order_completed_at_gt] = dates[:completed_at_gt]
        end

        if dates[:completed_at_lt].present?
          filters[:order_completed_at_lt] = dates[:completed_at_lt]
        end

        { q: filters }
      end
    end
  end
end
