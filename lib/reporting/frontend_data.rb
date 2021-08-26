# frozen_string_literal: true

module Reporting
  class FrontendData
    def initialize(current_user)
      @current_user = current_user
    end

    def distributors
      permissions.visible_enterprises_for_order_reports.is_distributor.
        select("enterprises.id, enterprises.name")
    end

    def suppliers
      permissions.visible_enterprises_for_order_reports.is_primary_producer.
        select("enterprises.id, enterprises.name")
    end

    def order_cycles
      OrderCycle.
        active_or_complete.
        visible_by(current_user).
        order('order_cycles.orders_close_at DESC')
    end

    private

    attr_reader :current_user

    def permissions
      @permissions ||= OpenFoodNetwork::Permissions.new(current_user)
    end
  end
end
