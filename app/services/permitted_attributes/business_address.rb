# frozen_string_literal: true

module PermittedAttributes
  class BusinessAddress
    def self.attributes
      [
        :company, :address1, :address2,
        :city, :country_id, :state_id, :zipcode,
        :phone
      ]
    end
  end
end
  