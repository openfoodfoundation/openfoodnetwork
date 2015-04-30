require 'spec_helper'

module Spree
  describe Payment do
    describe "available actions" do
      context "for most gateways" do
        let(:payment) { create(:payment, source: create(:credit_card)) }

        it "can capture and void" do
          payment.actions.sort.should == %w(capture void).sort
        end

        describe "when a payment has been taken" do
          before do
            payment.stub(:state) { 'completed' }
            payment.stub(:order) { double(:order, payment_state: 'credit_owed') }
          end

          it "can void and credit" do
            payment.actions.sort.should == %w(void credit).sort
          end
        end
      end

      context "for Pin Payments" do
        let(:d) { create(:distributor_enterprise) }
        let(:pin) { Gateway::Pin.create! name: 'pin', distributor_ids: [d.id]}
        let(:payment) { create(:payment, source: create(:credit_card), payment_method: pin) }

        it "does not void" do
          payment.actions.should_not include 'void'
        end

        describe "when a payment has been taken" do
          before do
            payment.stub(:state) { 'completed' }
            payment.stub(:order) { double(:order, payment_state: 'credit_owed') }
          end

          it "can refund instead of crediting" do
            payment.actions.should_not include 'credit'
            payment.actions.should     include 'refund'
          end
        end
      end
    end
  end
end
