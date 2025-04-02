# frozen_string_literal: true

# Mask user data from suppliers, unless explicitly allowed
# See also: lib/reporting/queries/mask_data.rb
#
module Orders
  class MaskDataService
    def initialize(order)
      @order = order
    end

    def call
      mask_customer_names unless customer_names_allowed?
      mask_contact_data unless cutomer_contacts_allowed?
      mask_address
    end

    private

    attr_accessor :order

    def customer_names_allowed?
      order.distributor.show_customer_names_to_suppliers
    end

    def mask_customer_names
      order.bill_address&.assign_attributes(firstname: I18n.t('admin.reports.hidden_field'),
                                            lastname: "")
      order.ship_address&.assign_attributes(firstname: I18n.t('admin.reports.hidden_field'),
                                            lastname: "")
    end

    def cutomer_contacts_allowed?
      order.distributor.show_customer_contacts_to_suppliers
    end

    def mask_contact_data
      order.bill_address&.assign_attributes(phone: "")
      order.ship_address&.assign_attributes(phone: "")
      order.assign_attributes(email: I18n.t('admin.reports.hidden_field'))
    end

    def mask_address
      order.bill_address&.assign_attributes(address1: "", address2: "",
                                            city: "", zipcode: "", state: nil)
      order.ship_address&.assign_attributes(address1: "", address2: "",
                                            city: "", zipcode: "", state: nil)
    end
  end
end
