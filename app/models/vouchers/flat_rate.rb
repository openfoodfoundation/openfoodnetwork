# frozen_string_literal: false

module Vouchers
  class FlatRate < Voucher
    include FlatRatable

    validates_with ScopedUniquenessValidator
  end
end
