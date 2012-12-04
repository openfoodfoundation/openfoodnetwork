class ExchangeFee < ActiveRecord::Base
  belongs_to :exchange
  belongs_to :enterprise_fee
end
