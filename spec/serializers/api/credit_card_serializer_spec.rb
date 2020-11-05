# frozen_string_literal: true

require 'spec_helper'

describe Api::CreditCardSerializer do
  let(:card) { create(:credit_card) }
  let(:serializer) { Api::CreditCardSerializer.new card }

  it "serializes a credit card" do
    expect(serializer.to_json).to match card.last_digits.to_s
  end

  it "formats an identifying string with the card number masked" do
    expect(serializer.formatted).to eq "Visa x-1111 Exp:#{card.month}/#{card.year}"
  end
end
