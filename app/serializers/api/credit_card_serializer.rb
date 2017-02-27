class Api::CreditCardSerializer < ActiveModel::Serializer
  attributes :id, :month, :year, :cc_type, :last_digits, :first_name, :last_name, :formatted

  def formatted
    elements = []
    elements << cc_type.capitalize if cc_type
    if last_digits
      3.times { elements << I18n.t(:card_masked_digit) * 4 }
    end
    elements << last_digits if last_digits
    elements << I18n.t(:card_expiry_abbreviation)
    elements << month.to_s + "/" + year.to_s if month # TODO: I18n
    elements.join(" ")
  end
end
