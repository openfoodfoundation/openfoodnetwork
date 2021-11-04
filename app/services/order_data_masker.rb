# frozen_string_literal: true

class OrderDataMasker
  def initialize(order)
    @order = order
  end

  def call
    mask_customer_names unless customer_names_allowed?
    mask_contact_data
  end

  private

  attr_accessor :order

  def customer_names_allowed?
    order.distributor.show_customer_names_to_suppliers
  end

  def mask_customer_names
    order.bill_address&.assign_attributes(firstname: I18n.t('admin.reports.hidden'),
                                          lastname: "")
    order.ship_address&.assign_attributes(firstname: I18n.t('admin.reports.hidden'),
                                          lastname: "")
  end

  def mask_contact_data
    order.bill_address&.assign_attributes(phone: "", address1: "", address2: "",
                                          city: "", zipcode: "", state: nil)
    order.ship_address&.assign_attributes(phone: "", address1: "", address2: "",
                                          city: "", zipcode: "", state: nil)
    order.assign_attributes(email: I18n.t('admin.reports.hidden'))
  end
end
