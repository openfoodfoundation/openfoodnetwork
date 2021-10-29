# frozen_string_literal: true

require 'active_support/concern'

module SetUnusedAddressFields
  extend ActiveSupport::Concern

  included do
    before_validation :set_unused_address_fields
  end

  def set_unused_address_fields
    ship_address.company = 'unused' if ship_address.present?
    bill_address.company = 'unused' if bill_address.present?
  end
end
