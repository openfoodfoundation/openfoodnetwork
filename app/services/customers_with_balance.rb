class CustomersWithBalance
  def initialize(enterprise_id)
    @enterprise_id = enterprise_id
  end

  def query
    Customer.of(enterprise_id).
      includes(:bill_address, :ship_address, user: :credit_cards).
      joins(:orders).
      merge(Spree::Order.complete.not_state(:canceled)).
      group("customers.id").
      select("customers.*").
      select("SUM(total - payment_total) AS balance_value")
  end

  private

  attr_reader :enterprise_id
end
