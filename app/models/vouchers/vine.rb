# frozen_string_literal: false

module Vouchers
  class Vine < Voucher
    include FlatRatable

    # a VINE voucher :
    #  - can potentially be associated with mutiple enterprise
    #  - code ( "short code" in VINE ) can be recycled, but they shouldn't be linked to the same
    #    voucher_id
    validates :code, uniqueness: { scope: [:enterprise_id, :external_voucher_id] }
  end
end
