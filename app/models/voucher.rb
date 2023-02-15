# frozen_string_literal: false

class Voucher < ApplicationRecord
  belongs_to :enterprise

  validates :code, presence: true, uniqueness: { scope: :enterprise_id }
end
