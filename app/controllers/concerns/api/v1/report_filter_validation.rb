# frozen_string_literal: true

module Api
  module V1
    module ReportFilterValidation
      DATE_QUERY_FILTERS = %i[completed_at_gt completed_at_lt].freeze

      private

      def validate_filters
        return if params[:order_cycle_id].present? || params[:distributor_id].present?

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.missing_report_filters"))
      end

      def validate_filter_ids
        valid = %i[order_cycle_id distributor_id].all? do |key|
          value = params[key]
          value.blank? || (value.is_a?(String) && value.match?(/\A[1-9]\d*\z/))
        end
        return if valid

        render status: :unprocessable_entity,
               json: json_api_error(I18n.t("api.invalid_resource"))
      end

      def validate_filter_records
        [
          [OrderCycle, params[:order_cycle_id]],
          [Enterprise, params[:distributor_id]]
        ].each do |model, id|
          next if id.blank? || model.where(id:).exists?

          raise ActiveRecord::RecordNotFound
        end
      end

      def validate_dates
        invalid_key = DATE_QUERY_FILTERS.find do |key|
          !valid_date?(permitted_params.dig(:q, key))
        end
        return unless invalid_key

        render status: :unprocessable_entity,
               json: json_api_error(
                 "#{invalid_key} #{DateTimeStringValidator.invalid_format_error}"
               )
      end

      def valid_date?(value)
        return true if value.nil? || value == ""

        value.is_a?(String) && Time.zone.parse(value).present?
      rescue ArgumentError, TypeError
        false
      end
    end
  end
end
