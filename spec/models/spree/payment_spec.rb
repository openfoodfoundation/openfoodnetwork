require 'spec_helper'

module Spree
  describe Payment do
    describe "available actions" do
      let(:payment) { create(:payment, source: create(:credit_card)) }

      context "for most gateways" do
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
    end
  end
end
