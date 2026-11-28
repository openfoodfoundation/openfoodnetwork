# frozen_string_literal: true

# The order cycles of a shop, as DFC SaleSessions.
#
# A DFC partner can read the products of an enterprise and the offer of a
# producer, but not the price that a buyer pays in an order cycle, which also
# depends on the distributor's price override and on the enterprise fees of the
# cycle. Each open cycle in which this enterprise is the distributor is
# published as one sale session listing those offers.
module DfcProvider
  class SaleSessionsController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def index
      require_permission "ReadProducts"

      sessions = order_cycles.map { |order_cycle| build_session(order_cycle) }
      render_dfc(sessions, *related_subjects(sessions))
    end

    def show
      require_permission "ReadProducts"

      session = build_session(order_cycle)
      render_dfc(session, *related_subjects([session]))
    end

    private

    def order_cycle
      @order_cycle ||= order_cycles.find(params.expect(:id))
    end

    # The cycles this enterprise distributes and that are accepting orders
    # right now. Cycles reserved to some customers with tag rules are included:
    # they are the point of this endpoint, and we can't tell a DFC client who
    # those customers are, nor expose them.
    def order_cycles
      OrderCycle.active.with_distributor(current_enterprise).distinct.order(:id)
    end

    def build_session(order_cycle)
      SaleSessionBuilder.for_cycle(order_cycle, current_enterprise)
    end

    # The offered products are the same subjects as the catalog items, so a
    # client that already read the catalog can match them.
    def related_subjects(sessions)
      offers = sessions.flat_map(&:offers)
      [*offers, *offers.map(&:offeredItem).uniq(&:semanticId)]
    end
  end
end
