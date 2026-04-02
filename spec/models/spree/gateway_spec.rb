# frozen_string_literal: true

RSpec.describe Spree::Gateway do
  subject(:gateway) { test_gateway.new }
  let(:test_gateway) do
    Class.new(Spree::Gateway) do
      def provider_class
        Class.new do
          def initialize(*); end

          def imaginary_method; end
        end
      end
    end
  end

  it "passes through all arguments on a method_missing call" do
    expect(Rails.env).to receive(:local?).and_return(false)
    expect(gateway.provider).to receive(:imaginary_method).with('foo')
    gateway.imaginary_method('foo')
  end

  it "raises an error in test env" do
    expect { gateway.imaginary_method('foo') }.to raise_error StandardError
  end

  describe "#can_capture?" do
    it "should be true if payment is pending" do
      payment = build_stubbed(:payment, created_at: Time.zone.now)
      allow(payment).to receive(:pending?) { true }
      expect(gateway.can_capture_and_complete_order?(payment)).to be_truthy
    end

    it "should be true if payment is checkout" do
      payment = build_stubbed(:payment, created_at: Time.zone.now)
      allow(payment).to receive_messages pending?: false,
                                         checkout?: true
      expect(gateway.can_capture_and_complete_order?(payment)).to be_truthy
    end
  end

  describe "#can_void?" do
    it "should be true if payment is not void" do
      payment = build_stubbed(:payment)
      allow(payment).to receive(:void?) { false }
      expect(gateway.can_void?(payment)).to be_truthy
    end
  end

  describe "#can_credit?" do
    it "should be false if payment is not completed" do
      payment = build_stubbed(:payment)
      allow(payment).to receive(:completed?) { false }
      expect(gateway.can_credit?(payment)).to be_falsy
    end

    it "should be false when order payment_state is not 'credit_owed'" do
      payment = build_stubbed(:payment,
                              order: create(:order, payment_state: 'paid'))
      allow(payment).to receive(:completed?) { true }
      expect(gateway.can_credit?(payment)).to be_falsy
    end

    it "should be false when credit_allowed is zero" do
      payment = build_stubbed(:payment,
                              order: create(:order, payment_state: 'credit_owed'))
      allow(payment).to receive_messages completed?: true,
                                         credit_allowed: 0

      expect(gateway.can_credit?(payment)).to be_falsy
    end
  end
end
