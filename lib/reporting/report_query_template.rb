# frozen_string_literal: true

# This is the new report template that use QueryBuilder to directly get the data from the DB
module Reporting
  class ReportQueryTemplate < ReportTemplate
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
