require 'spec_helper'

module Spree
  describe Payment do
    describe "available actions" do
      context "for most gateways" do
        let(:payment) { create(:payment, source: create(:credit_card)) }

        it "can capture and void" do
          payment.actions.should match_array %w(capture void)
        end

        describe "when a payment has been taken" do
          before do
            payment.stub(:state) { 'completed' }
            payment.stub(:order) { double(:order, payment_state: 'credit_owed') }
          end

          it "can void and credit" do
            payment.actions.should match_array %w(void credit)
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

    describe "refunding" do
      let(:payment) { create(:payment) }
      let(:success) { double(:success? => true, authorization: 'abc123') }
      let(:failure) { double(:success? => false) }

      it "always checks the environment" do
        payment.payment_method.stub(:refund) { success }
        payment.should_receive(:check_environment)
        payment.refund!
      end

      describe "calculating refund amount" do
        it "returns the parameter amount when given" do
          payment.send(:calculate_refund_amount, 123).should === 123.0
        end

        it "refunds up to the value of the payment when the outstanding balance is larger" do
          payment.stub(:credit_allowed) { 123 }
          payment.stub(:order) { double(:order, outstanding_balance: 1000) }
          payment.send(:calculate_refund_amount).should == 123
        end

        it "refunds up to the outstanding balance of the order when the payment is larger" do
          payment.stub(:credit_allowed) { 1000 }
          payment.stub(:order) { double(:order, outstanding_balance: 123) }
          payment.send(:calculate_refund_amount).should == 123
        end
      end

      describe "performing refunds" do
        before do
          payment.stub(:calculate_refund_amount) { 123 }
          payment.payment_method.should_receive(:refund).and_return(success)
        end

        it "performs the refund without payment profiles" do
          payment.payment_method.stub(:payment_profiles_supported?) { false }
          payment.refund!
        end

        it "performs the refund with payment profiles" do
          payment.payment_method.stub(:payment_profiles_supported?) { true }
          payment.refund!
        end
      end

      it "records the response" do
        payment.stub(:calculate_refund_amount) { 123 }
        payment.payment_method.stub(:refund).and_return(success)
        payment.should_receive(:record_response).with(success)
        payment.refund!
      end

      it "records a payment on success" do
        payment.stub(:calculate_refund_amount) { 123 }
        payment.payment_method.stub(:refund).and_return(success)
        payment.stub(:record_response)

        expect do
          payment.refund!
        end.to change(Payment, :count).by(1)

        p = Payment.last
        p.order.should == payment.order
        p.source.should == payment
        p.payment_method.should == payment.payment_method
        p.amount.should == -123
        p.response_code.should == success.authorization
        p.state.should == 'completed'
      end

      it "logs the error on failure" do
        payment.stub(:calculate_refund_amount) { 123 }
        payment.payment_method.stub(:refund).and_return(failure)
        payment.stub(:record_response)
        payment.should_receive(:gateway_error).with(failure)
        payment.refund!
      end
    end
  end
end
