class ExchangeFee < ActiveRecord::Base
  belongs_to :exchange
  belongs_to :enterprise_fee


  after_save :refresh_products_cache
  after_destroy :refresh_products_cache


  private

  def refresh_products_cache
    exchange.refresh_products_cache
  end
end
