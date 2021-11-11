# frozen_string_literal: true

module Reporting
  class ReportTemplate
    delegate :as_json, :as_arrays, :table_headers, :table_rows,
             :to_csv, :to_xlsx, :to_ods, :to_json, to: :renderer

    attr_reader :options

    SUBTYPES = []

    def self.report_subtypes
      self::SUBTYPES
    end

    def initialize(current_user, ransack_params, options = {})
      @current_user = current_user
      @ransack_params = ransack_params.with_indifferent_access
      @options = ( options || {} ).with_indifferent_access
    end

    def report_data
      @report_data ||= report_query.raw_result
    end

    private

    attr_reader :current_user, :ransack_params

    def renderer
      @renderer ||= ReportRenderer.new(self)
    end

    def scoped_orders_relation
      visible_orders_relation.ransack(ransack_params).result
    end

    def visible_orders_relation
      ::Permissions::Order.new(current_user).
        visible_orders.complete.not_state(:canceled).
        select(:id).distinct
    end

    def visible_line_items_relation
      ::Permissions::Order.new(current_user).
        visible_line_items.
        select(:id).distinct
    end

    def managed_orders_relation
      ::Enterprise.managed_by(current_user).select(:id).distinct
    end

    def i18n_scope
      "admin.reports"
    end
  end
end
