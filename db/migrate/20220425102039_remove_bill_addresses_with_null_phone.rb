class RemoveBillAddressesWithNullPhone < ActiveRecord::Migration[6.1]
  class BillAddress < ActiveRecord::Base
    self.table_name = "spree_addresses"

    scope :invalid, -> { where(phone: nil) }
  end

  class SpreeUser < ActiveRecord::Base
    belongs_to :bill_address

    def self.invalid_bill_address_ids
      joins(:bill_address).merge(BillAddress.invalid).pluck(:bill_address_id)
    end
  end

  def up
    address_ids = SpreeUser.invalid_bill_address_ids
    SpreeUser.where(bill_address_id: address_ids).update_all(bill_address_id: nil)
    BillAddress.where(id: address_ids).delete_all
  end
end
