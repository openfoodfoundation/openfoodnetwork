# frozen_string_literal: true

RSpec.describe Reporting::Reports::EnterpriseFeeSummary::EnterpriseFeesWithTaxReportByProducer do
  let(:current_user) { create(:admin_user) }

  let(:enterprise) {
    create(:distributor_enterprise_with_tax, is_primary_producer: true,
                                             shipping_methods: [shipping_method])
  }
  let(:shipping_method) { create(:shipping_method) }
  let(:order_cycle) {
    create(:simple_order_cycle, coordinator: enterprise).tap do |order_cycle|
      incoming = order_cycle.exchanges.create!(incoming: true, sender: enterprise,
                                               receiver: enterprise)
      outgoing = order_cycle.exchanges.create!(incoming: false, sender: enterprise,
                                               receiver: enterprise)

      supplier_fee = create(:enterprise_fee, :per_item, enterprise:, amount: 15,
                                                        name: 'Transport',
                                                        fee_type: 'transport',)
      incoming.exchange_fees.create!(enterprise_fee: supplier_fee)

      incoming.exchange_variants.create(variant:)
      outgoing.exchange_variants.create(variant:)
    end
  }
  let(:variant) { create(:variant, supplier: enterprise) }
  let(:order) {
    create(
      :order, :with_line_item,
      variant:, distributor: enterprise, order_cycle:,
      shipping_method:, ship_address: create(:address)
    ).tap do |order|
      order.recreate_all_fees!
      Orders::WorkflowService.new(order).complete!
    end
  }

  it "renders an empty report" do
    report = described_class.new(current_user)
    expect(report.query_result).to eq({})
  end

  it "lists orders" do
    order
    report = described_class.new(current_user)
    expect(report.query_result.values).to eq [[order]]
  end

  it "handles products removed from the order cycle" do
    order
    order_cycle.exchanges.incoming.first.exchange_variants.first.destroy!

    report = described_class.new(current_user)

    expect(report.query_result.values).to eq [[order]]
  end
end
