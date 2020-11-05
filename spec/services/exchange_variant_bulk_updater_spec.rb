# frozen_string_literal: true

require 'spec_helper'

describe ExchangeVariantBulkUpdater do
  let!(:first_variant) { create(:variant) }
  let!(:second_variant) { create(:variant) }
  let!(:third_variant) { create(:variant) }

  it 'associates new variants to the exchange' do
    exchange = create(:exchange)

    described_class.new(exchange).update!([first_variant.id, second_variant.id])

    # Check association cache.
    expect(exchange.variants).to include(first_variant)
    expect(exchange.variants).to include(second_variant)
    # Check if changes are actually persisted.
    exchange.reload
    expect(exchange.variants).to include(first_variant)
    expect(exchange.variants).to include(second_variant)
  end

  it 'disassociates variants from the exchange' do
    exchange = create(:exchange, variant_ids: [first_variant.id, second_variant.id])

    described_class.new(exchange).update!([first_variant.id, third_variant.id])

    # Check association cache.
    expect(exchange.variants).to include(first_variant)
    expect(exchange.variants).to include(third_variant)
    # Check if changes are actually persisted.
    exchange.reload
    expect(exchange.variants).to include(first_variant)
    expect(exchange.variants).to include(third_variant)

    described_class.new(exchange).update!([])

    # Check association cache.
    expect(exchange.variants).to be_blank
    # Check if changes are actually persisted.
    exchange.reload
    expect(exchange.variants).to be_blank
  end
end
