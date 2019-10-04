class CoordinatorFee < ActiveRecord::Base
  belongs_to :order_cycle
  belongs_to :enterprise_fee
end
