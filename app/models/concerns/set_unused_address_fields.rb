require 'active_support/concern'

module SetUnusedAddressFields 
  extend ActiveSupport::Concern

  included do
    self.before_validation :set_unused_address_fields
  end

  def set_unused_address_fields
    ship_address.company = 'Company' if ship_address.present?
    bill_address.company = 'Company' if bill_address.present?
  end
end
