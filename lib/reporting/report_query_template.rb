# frozen_string_literal: true

# This is the new report template that use QueryBuilder to directly get the data from the DB
module Reporting
  class ReportQueryTemplate < ReportTemplate
    attr_reader :options

    SUBTYPES = [].freeze

    def self.report_subtypes
      self::SUBTYPES
    end

    def initialize(current_user, ransack_params, options = {})
      @current_user = current_user
      @ransack_params = ( ransack_params || {} ).with_indifferent_access
      @options = ( options || {} ).with_indifferent_access
    end

    def report_data
      @report_data ||= report_query.raw_result
    end

    def report_query
      raise NotImplementedError
    end

    def table_headers
      report_data.columns
    end

    def table_rows
      report_data.rows
    end

    private

    attr_reader :current_user, :ransack_params

    def ransacked_orders_relation
      visible_orders_relation.ransack(ransack_params).result
    end

    def ransacked_line_items_relation
      visible_line_items_relation.ransack(ransack_params).result
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
