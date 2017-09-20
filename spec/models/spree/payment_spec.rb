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

    describe "applying transaction fees" do
      let!(:order) { create(:order) }
      let!(:line_item) { create(:line_item, order: order, quantity: 3, price: 5.00) }

      # Mimicing call from PayPalController#confirm in spree_paypal_express
      def create_new_paypal_express_payment(order, payment_method)
        order.payments.create!({
          :source => Spree::PaypalExpressCheckout.create({
            :token => "123",
            :payer_id => "456"
          }, :without_protection => true),
          :amount => order.total,
          :payment_method => payment_method
        }, :without_protection => true)
      end

      before do
        order.update_totals
      end

      context "for paypal express payments with transaction fees" do
        let!(:payment_method) { Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress", distributor_ids: [create(:distributor_enterprise).id], environment: Rails.env) }
        let(:calculator) { Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

        before do
          payment_method.calculator = calculator
          payment_method.save!
        end

        context "when a payment already exists on the order" do
          let!(:existing_payment) do
            order.payments.create!(payment_method_id: payment_method.id, amount: order.total)
          end

          context "and the existing payment uses the same payment method" do
            context "and the existing payment does not have a source" do
              it "removes the existing payment (and associated fees)" do
                new_payment = create_new_paypal_express_payment(order, payment_method)

                order.reload
                expect(order.payments.count).to eq 1
                expect(order.payments).to include new_payment
                expect(order.payments).to_not include existing_payment
                expect(order.adjustments.payment_fee.count).to eq 1
                expect(order.adjustments.payment_fee.first.amount).to eq 1.5
              end
            end

            context "and the existing payment has a source" do
              let!(:source) { Spree::PaypalExpressCheckout.create(token: "123") }

              before do
                existing_payment.source = source
                existing_payment.save!
              end

              it "does not remove or invalidate the existing payment" do
                new_payment = create_new_paypal_express_payment(order, payment_method)

                order.reload
                expect(order.payments.count).to eq 2
                expect(order.payments).to include new_payment, existing_payment
                expect(new_payment.state).to eq "checkout"
                expect(existing_payment.state).to eq "checkout"
              end
            end
          end

          context "and the existing payment uses a different method" do
            let!(:another_payment_method) { Spree::Gateway::PayPalExpress.create!(name: "PayPalExpress", distributor_ids: [create(:distributor_enterprise).id], environment: Rails.env) }

            before do
              existing_payment.update_attributes(payment_method_id: another_payment_method.id)
            end

            it "does not remove or invalidate the existing payment" do
              new_payment = create_new_paypal_express_payment(order, payment_method)

              order.reload
              expect(order.payments).to include new_payment, existing_payment
              expect(new_payment.state).to eq "checkout"
              expect(existing_payment.state).to eq "checkout"
            end
          end
        end
      end
    end
  end
end
