class Api::CreditCardSerializer < ActiveModel::Serializer
  attributes :id, :formatted, :delete_link

  def formatted
    elements = []
    elements << object.cc_type.capitalize if object.cc_type
    if object.last_digits
      3.times { elements << I18n.t(:card_masked_digit) * 4 }
      elements << object.last_digits
    end
    elements << I18n.t(:card_expiry_abbreviation)
    elements << object.month.to_s + "/" + object.year.to_s if object.month # TODO: I18n
    elements.join(" ")
  end

  def delete_link
    Spree::Core::Engine.routes.url_helpers.credit_card_path(object.id)
  end
end
