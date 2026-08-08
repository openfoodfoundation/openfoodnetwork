# frozen_string_literal: true

class FakeSubscriptionSummary
  attr_reader :shop_id, :type

  def initialize(shop_id:, type:, orders:)
    @shop_id = shop_id
    @type = type
    @orders = orders
  end

  def order_count
    @orders.count
  end

  def issue_count
    1
  end

  def success_count
    order_count - issue_count
  end

  def issues
    {
      payment: {
        @orders.first.id => "Payment failed"
      }
    }
  end

  def orders_affected_by(_type)
    @orders
  end

  def unrecorded_ids
    []
  end

  def subscription_issues
    []
  end
end
