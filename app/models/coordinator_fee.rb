# frozen_string_literal: true

class CoordinatorFee < ApplicationRecord
  self.belongs_to_required_by_default = true

  belongs_to :order_cycle
  belongs_to :enterprise_fee
end
