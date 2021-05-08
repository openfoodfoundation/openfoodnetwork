class ExchangeFee < ApplicationRecord
  belongs_to :exchange
  belongs_to :enterprise_fee
end
