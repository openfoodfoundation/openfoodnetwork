# frozen_string_literal: true

class ExchangeFee < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :exchange
  belongs_to :enterprise_fee
end
