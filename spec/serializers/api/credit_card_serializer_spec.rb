# frozen_string_literal: true

RSpec.describe Api::CreditCardSerializer do
  let(:card) { create(:credit_card) }
  let(:serializer) { Api::CreditCardSerializer.new card }

  it "serializes a credit card" do
    expect(serializer.as_json).to include(
      id: card.id,
      cc_type: "Visa",
      number: "x-1111"
    )
  end

  it "formats an identifying string with the card number masked" do
    expect(serializer.formatted).to eq "Visa x-1111 Exp:#{card.month}/#{card.year}"
  end
end
