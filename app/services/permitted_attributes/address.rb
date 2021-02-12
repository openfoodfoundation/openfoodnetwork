# frozen_string_literal: true

module PermittedAttributes
  class Address
    def self.attributes
      [
        :firstname, :lastname, :address1, :address2,
        :city, :country_id, :state_id, :zipcode,
        :phone, :state_name, :alternative_phone, :company,
        :latitude, :longitude
      ]
    end
  end
end
