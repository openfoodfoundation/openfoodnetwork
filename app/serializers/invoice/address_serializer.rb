# frozen_string_literal: false

class Invoice
  class AddressSerializer < ActiveModel::Serializer
    attributes :firstname, :lastname, :address1, :address2, :city, :zipcode, :phone, :company
    has_one :state, serializer: Invoice::StateSerializer
  end
end
