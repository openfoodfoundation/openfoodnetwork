class CoordinatorFee < ActiveRecord::Base
  belongs_to :order_cycle
  belongs_to :enterprise_fee

  after_save :refresh_products_cache
  after_destroy :refresh_products_cache


  private

  def refresh_products_cache
    order_cycle.refresh_products_cache
  end

end
