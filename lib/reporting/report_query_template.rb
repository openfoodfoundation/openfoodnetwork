# frozen_string_literal: true

# This is the new report template that use QueryBuilder to directly get the data from the DB
module Reporting
  class ReportQueryTemplate < ReportTemplate
    def report_data
      @report_data ||= report_query.raw_result
    end
    alias_method :query_result, :report_data

    def report_query
      raise NotImplementedError
    end

    # ReportQueryTemplate work differently than ReportObjectTemplate
    # Here the query_result is already the expected result, so we just create
    # a fake columns method to copy the sql result into the row result
    def columns
      report_data.columns.map { |field| [field.to_sym, proc { |data| data[field] }] }.to_h
    end

    def table_rows
      report_data.rows
    end

    def search
      visible_line_items_relation.ransack(ransack_params)
    end

    private

    def ransacked_line_items_relation
      search.result
    end

    def visible_orders_relation
      ::Permissions::Order.new(user).
        visible_orders.complete.not_state(:canceled).
        select(:id).distinct
    end

    def visible_line_items_relation
      ::Permissions::Order.new(user).
        visible_line_items.
        select(:id).distinct
    end

    def managed_orders_relation
      ::Enterprise.managed_by(user).select(:id).distinct
    end

    def i18n_scope
      "admin.reports"
    end
  end
end
