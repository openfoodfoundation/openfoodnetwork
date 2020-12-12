# frozen_string_literal: true

# allows credit card info to be saved to the database which is needed for factories to work properly
class TestCard < Spree::CreditCard
  def remove_readonly_attributes(attributes) attributes; end
end

FactoryBot.define do
  factory :credit_card, class: TestCard do
    verification_value { 123 }
    month { 12 }
    year { Time.zone.now.year + 1 }
    number { '4111111111111111' }

    cc_type { 'visa' }
  end

  # A card that has been added to the user's profile and can be re-used.
  factory :stored_credit_card, parent: :credit_card do
    gateway_customer_profile_id { "cus_F2T..." }
    gateway_payment_profile_id { "card_1EY..." }
  end
end
