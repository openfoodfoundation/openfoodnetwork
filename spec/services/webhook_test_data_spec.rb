# frozen_string_literal: true

RSpec.describe WebhookTestData do
  describe ".order" do
    it "describes an order with a line item" do
      order = described_class.order

      expect(order.number).to eq "R555555555"
      expect(order.line_items.map(&:price)).to eq [20.00]
    end

    it "accepts overrides" do
      expect(described_class.order(total: 20.00).total).to eq 20.00
    end
  end

  describe ".payment" do
    it "describes a completed payment with a payment method" do
      payment = described_class.payment

      expect(payment.state).to eq "completed"
      expect(payment.payment_method.name).to eq "Test payment method"
    end

    it "accepts overrides" do
      expect(described_class.payment(state: "checkout").state).to eq "checkout"
    end
  end

  describe ".enterprise" do
    it "describes an enterprise with an address" do
      enterprise = described_class.enterprise

      expect(enterprise.name).to eq "TEST Enterprise"
      expect(enterprise.address.city).to eq "TestCity"
    end
  end

  it "can't be saved to the database" do
    order = described_class.order
    payment = described_class.payment
    enterprise = described_class.enterprise
    records = [
      order,
      order.line_items.first,
      payment,
      payment.payment_method,
      enterprise,
      enterprise.address,
    ]

    expect(records).to all(be_readonly)
    records.each do |record|
      # Skipping validation so we reach the readonly guard rather than
      # failing earlier on incomplete test data.
      expect{ record.save!(validate: false) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
