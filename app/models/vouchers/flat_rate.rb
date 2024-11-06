# frozen_string_literal: false

module Vouchers
  class FlatRate < Voucher
    include FlatRatable

    validates :code, uniqueness: { scope: :enterprise_id }
  end
end
