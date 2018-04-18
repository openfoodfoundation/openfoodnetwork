module Api
  class CreditCardSerializer < ActiveModel::Serializer
    attributes :id, :brand, :number, :expiry, :formatted, :delete_link, :is_default

    def brand
      object.cc_type.capitalize
    end

    def number
      "x-#{object.last_digits}"
    end

    def expiry
      m = object.month.to_i
      m = m < 10 ? "0#{m}" : m.to_s
      "#{m}/#{object.year}"
    end

    def formatted
      "#{brand} #{number} #{I18n.t(:card_expiry_abbreviation)}:#{expiry}"
    end

    def delete_link
      Spree::Core::Engine.routes.url_helpers.credit_card_path(object.id)
    end
  end
end
