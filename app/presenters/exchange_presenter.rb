class ExchangePresenter
  attr_accessor :exchange

  def initialize(exchange)
    @exchange = exchange
  end

  delegate :id, :sender_id, :receiver_id, :exchange_variants, :to => :exchange

  def exchange_products
    @exchange.exchange_variants.group_by { |ev| ev.variant.product }
  end

end
