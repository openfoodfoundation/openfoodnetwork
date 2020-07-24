# frozen_string_literal: true

require 'open_food_network/order_grouper'

module OrderManagement
  module Reports
    module BulkCoop
      class ReportService
        attr_accessor :permissions, :parameters, :user

        def initialize(permissions, parameters, user)
          @permissions = permissions
          @parameters = parameters
          @user = user
          @report = BulkCoopReport.new(user, parameters, true)
        end

        def header
          @report.header
        end

        def list
          order_grouper = OpenFoodNetwork::OrderGrouper.new @report.rules, @report.columns, @report
          order_grouper.table(@report.table_items)
        end
      end
    end
  end
end
