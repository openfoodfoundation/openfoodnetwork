require 'spec_helper'
require 'spree/core/gateway_error'

describe Spree::Payment do
  context 'original specs from Spree' do
    let(:order) { create(:order) }
    let(:gateway) do
      gateway = Spree::Gateway::Bogus.new(:environment => 'test', :active => true)
      gateway.stub :source_required => true
      gateway
    end

    let(:card) { create(:credit_card) }

    before { allow(card).to receive(:has_payment_profile?).and_return(true) }

    let(:payment) do
      payment = create(:payment)
      payment.source = card
      payment.order = order
      payment.payment_method = gateway
      payment
    end

    let(:amount_in_cents) { payment.amount.to_f * 100 }

    let!(:success_response) do
      double('success_response', :success? => true,
             :authorization => '123',
             :avs_result => { 'code' => 'avs-code' },
             :cvv_result => { 'code' => 'cvv-code', 'message' => "CVV Result"})
    end

    let(:failed_response) { double('gateway_response', :success? => false) }

    before(:each) do
      # So it doesn't create log entries every time a processing method is called
      allow(payment).to receive(:record_response)
    end

    context "extends LocalizedNumber" do
      it_behaves_like "a model using the LocalizedNumber module", [:amount]
    end

    context 'validations' do
      it "returns useful error messages when source is invalid" do
        payment.source = Spree::CreditCard.new
        expect(payment).not_to be_valid
        cc_errors = payment.errors['Credit Card']
        expect(cc_errors).to include("Number can't be blank")
        expect(cc_errors).to include("Month is not a number")
        expect(cc_errors).to include("Year is not a number")
        expect(cc_errors).to include("Verification Value can't be blank")
      end
    end

    # Regression test for https://github.com/spree/spree/pull/2224
    context 'failure' do
      it 'should transition to failed from pending state' do
        payment.state = 'pending'
        payment.failure
        expect(payment.state).to eql('failed')
      end

      it 'should transition to failed from processing state' do
        payment.state = 'processing'
        payment.failure
        expect(payment.state).to eql('failed')
      end

    end

    context 'invalidate' do
      it 'should transition from checkout to invalid' do
        payment.state = 'checkout'
        payment.invalidate
        expect(payment.state).to eq('invalid')
      end
    end

    context "processing" do
      before do
        payment.stub(:update_order)
        payment.stub(:create_payment_profile)
      end

      context "#process!" do
        it "should purchase if with auto_capture" do
          payment.payment_method.should_receive(:auto_capture?).and_return(true)
          payment.should_receive(:purchase!)
          payment.process!
        end

        it "should authorize without auto_capture" do
          payment.payment_method.should_receive(:auto_capture?).and_return(false)
          payment.should_receive(:authorize!)
          payment.process!
        end

        it "should make the state 'processing'" do
          payment.should_receive(:started_processing!)
          payment.process!
        end

        it "should invalidate if payment method doesnt support source" do
          payment.payment_method.should_receive(:supports?).with(payment.source).and_return(false)
          expect { payment.process!}.to raise_error(Spree::Core::GatewayError)
          expect(payment.state).to eq('invalid')
        end

      end

      context "#authorize" do
        it "should call authorize on the gateway with the payment amount" do
          payment.payment_method.should_receive(:authorize).with(amount_in_cents,
                                                                 card,
                                                                 anything).and_return(success_response)
          payment.authorize!
        end

        it "should call authorize on the gateway with the currency code" do
          payment.stub :currency => 'GBP'
          payment.payment_method.should_receive(:authorize).with(amount_in_cents,
                                                                 card,
                                                                 hash_including({:currency => "GBP"})).and_return(success_response)
          payment.authorize!
        end

        it "should log the response" do
          payment.authorize!
          expect(payment).to have_received(:record_response)
        end

        context "when gateway does not match the environment" do
          it "should raise an exception" do
            gateway.stub :environment => "foo"
            expect { payment.authorize! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "if successful" do
          before do
            payment.payment_method.should_receive(:authorize).with(amount_in_cents,
                                                                   card,
                                                                   anything).and_return(success_response)
          end

          it "should store the response_code, avs_response and cvv_response fields" do
            payment.authorize!
            expect(payment.response_code).to eq('123')
            expect(payment.avs_response).to eq('avs-code')
            expect(payment.cvv_response_code).to eq('cvv-code')
            expect(payment.cvv_response_message).to eq('CVV Result')
          end

          it "should make payment pending" do
            payment.should_receive(:pend!)
            payment.authorize!
          end
        end

        context "if unsuccessful" do
          it "should mark payment as failed" do
            gateway.stub(:authorize).and_return(failed_response)
            payment.should_receive(:failure)
            payment.should_not_receive(:pend)
            expect {
              payment.authorize!
            }.to raise_error(Spree::Core::GatewayError)
          end
        end
      end

      context "purchase" do
        it "should call purchase on the gateway with the payment amount" do
          gateway.should_receive(:purchase).with(amount_in_cents, card, anything).and_return(success_response)
          payment.purchase!
        end

        it "should log the response" do
          payment.purchase!
          expect(payment).to have_received(:record_response)
        end

        context "when gateway does not match the environment" do
          it "should raise an exception" do
            gateway.stub :environment => "foo"
            expect { payment.purchase!  }.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "if successful" do
          before do
            payment.payment_method.should_receive(:purchase).with(amount_in_cents,
                                                                  card,
                                                                  anything).and_return(success_response)
          end

          it "should store the response_code and avs_response" do
            payment.purchase!
            expect(payment.response_code).to eq('123')
            expect(payment.avs_response).to eq('avs-code')
          end

          it "should make payment complete" do
            payment.should_receive(:complete!)
            payment.purchase!
          end
        end

        context "if unsuccessful" do
          it "should make payment failed" do
            gateway.stub(:purchase).and_return(failed_response)
            payment.should_receive(:failure)
            payment.should_not_receive(:pend)
            expect { payment.purchase! }.to raise_error(Spree::Core::GatewayError)
          end
        end
      end

      context "#capture" do
        before do
          payment.stub(:complete).and_return(true)
        end

        context "when payment is pending" do
          before do
            payment.state = 'pending'
          end

          context "if successful" do
            before do
              payment.payment_method.should_receive(:capture).with(payment, card, anything).and_return(success_response)
            end

            it "should make payment complete" do
              payment.should_receive(:complete)
              payment.capture!
            end

            it "should store the response_code" do
              gateway.stub :capture => success_response
              payment.capture!
              expect(payment.response_code).to eq('123')
            end
          end

          context "if unsuccessful" do
            it "should not make payment complete" do
              gateway.stub :capture => failed_response
              payment.should_receive(:failure)
              payment.should_not_receive(:complete)
              expect { payment.capture! }.to raise_error(Spree::Core::GatewayError)
            end
          end
        end

        # Regression test for #2119
        context "when payment is completed" do
          before do
            payment.state = 'completed'
          end

          it "should do nothing" do
            payment.should_not_receive(:complete)
            payment.payment_method.should_not_receive(:capture)
            payment.log_entries.should_not_receive(:create)
            payment.capture!
          end
        end
      end

      context "#void" do
        before do
          payment.response_code = '123'
          payment.state = 'pending'
        end

        context "when profiles are supported" do
          it "should call payment_gateway.void with the payment's response_code" do
            gateway.stub :payment_profiles_supported? => true
            gateway.should_receive(:void).with('123', card, anything).and_return(success_response)
            payment.void_transaction!
          end
        end

        context "when profiles are not supported" do
          it "should call payment_gateway.void with the payment's response_code" do
            gateway.stub :payment_profiles_supported? => false
            gateway.should_receive(:void).with('123', anything).and_return(success_response)
            payment.void_transaction!
          end
        end

        it "should log the response" do
          payment.void_transaction!
          expect(payment).to have_received(:record_response)
        end

        context "when gateway does not match the environment" do
          it "should raise an exception" do
            gateway.stub :environment => "foo"
            expect { payment.void_transaction! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "if successful" do
          it "should update the response_code with the authorization from the gateway" do
            # Change it to something different
            payment.response_code = 'abc'
            payment.void_transaction!
            expect(payment.response_code).to eq('12345')
          end
        end

        context "if unsuccessful" do
          it "should not void the payment" do
            gateway.stub :void => failed_response
            payment.should_not_receive(:void)
            expect { payment.void_transaction! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        # Regression test for #2119
        context "if payment is already voided" do
          before do
            payment.state = 'void'
          end

          it "should not void the payment" do
            payment.payment_method.should_not_receive(:void)
            payment.void_transaction!
          end
        end
      end

      context "#credit" do
        before do
          payment.state = 'completed'
          payment.response_code = '123'
        end

        context "when outstanding_balance is less than payment amount" do
          before do
            payment.order.stub :outstanding_balance => 10
            payment.stub :credit_allowed => 1000
          end

          it "should call credit on the gateway with the credit amount and response_code" do
            gateway.should_receive(:credit).with(1000, card, '123', anything).and_return(success_response)
            payment.credit!
          end
        end

        context "when outstanding_balance is equal to payment amount" do
          before do
            payment.order.stub :outstanding_balance => payment.amount
          end

          it "should call credit on the gateway with the credit amount and response_code" do
            gateway.should_receive(:credit).with(amount_in_cents, card, '123', anything).and_return(success_response)
            payment.credit!
          end
        end

        context "when outstanding_balance is greater than payment amount" do
          before do
            payment.order.stub :outstanding_balance => 101
          end

          it "should call credit on the gateway with the original payment amount and response_code" do
            gateway.should_receive(:credit).with(amount_in_cents.to_f, card, '123', anything).and_return(success_response)
            payment.credit!
          end
        end

        it "should log the response" do
          payment.credit!
          expect(payment).to have_received(:record_response)
        end

        context "when gateway does not match the environment" do
          it "should raise an exception" do
            gateway.stub :environment => "foo"
            expect { payment.credit! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "when response is successful" do
          it "should create an offsetting payment" do
            expect(Spree::Payment).to receive(:create!)
            payment.credit!
          end

          it "resulting payment should have correct values" do
            allow(payment.order).to receive(:outstanding_balance) { 100 }
            allow(payment).to receive(:credit_allowed) { 10 }

            offsetting_payment = payment.credit!
            expect(offsetting_payment.amount.to_f).to eq(-10)
            expect(offsetting_payment).to be_completed
            expect(offsetting_payment.response_code).to eq('12345')
            expect(offsetting_payment.source).to eq(payment)
          end

          context 'and the source payment card is expired' do
            let(:card) do
              Spree::CreditCard.new(month: 12, year: 1995, number: '4111111111111111')
            end

            let(:successful_response) do
              ActiveMerchant::Billing::Response.new(true, "Yay!")
            end

            it 'lets the new payment to be saved' do
              allow(payment.order).to receive(:outstanding_balance) { 100 }
              allow(payment).to receive(:credit_allowed) { 10 }

              offsetting_payment = payment.credit!

              expect(offsetting_payment).to be_valid
            end
          end
        end
      end
    end

    context "when response is unsuccessful" do
      it "should not create a payment" do
        gateway.stub :credit => failed_response
        Spree::Payment.should_not_receive(:create)
        expect { payment.credit! }.to raise_error(Spree::Core::GatewayError)
      end
    end

    context "when already processing" do
      it "should return nil without trying to process the source" do
        payment.state = 'processing'

        payment.should_not_receive(:authorize!)
        payment.should_not_receive(:purchase!)
        expect(payment.process!).to be_nil
      end
    end

    context "with source required" do
      context "raises an error if no source is specified" do
        before do
          payment.source = nil
        end

        specify do
          expect { payment.process! }.to raise_error(Spree::Core::GatewayError, Spree.t(:payment_processing_failed))
        end
      end
    end

    context "with source optional" do
      context "raises no error if source is not specified" do
        before do
          payment.source = nil
          payment.payment_method.stub(:source_required? => false)
        end

        specify do
          expect { payment.process! }.not_to raise_error
        end
      end
    end

    context "#credit_allowed" do
      it "is the difference between offsets total and payment amount" do
        payment.amount = 100
        payment.stub(:offsets_total).and_return(0)
        expect(payment.credit_allowed).to eq(100)
        payment.stub(:offsets_total).and_return(80)
        expect(payment.credit_allowed).to eq(20)
      end
    end

    context "#can_credit?" do
      it "is true if credit_allowed > 0" do
        payment.stub(:credit_allowed).and_return(100)
        expect(payment.can_credit?).to be true
      end
      it "is false if credit_allowed is 0" do
        payment.stub(:credit_allowed).and_return(0)
        expect(payment.can_credit?).to be false
      end
    end

    context "#credit" do
      context "when amount <= credit_allowed" do
        it "makes the state processing" do
          payment.payment_method.name = 'Gateway'
          payment.payment_method.distributors << create(:distributor_enterprise)
          payment.payment_method.save!

          payment.order = create(:order)

          payment.state = 'completed'
          payment.stub(:credit_allowed).and_return(10)
          payment.partial_credit(10)
          expect(payment).to be_processing
        end
        it "calls credit on the source with the payment and amount" do
          payment.state = 'completed'
          payment.stub(:credit_allowed).and_return(10)
          payment.should_receive(:credit!).with(10)
          payment.partial_credit(10)
        end
      end
      context "when amount > credit_allowed" do
        it "should not call credit on the source" do
          payment.state = 'completed'
          payment.stub(:credit_allowed).and_return(10)
          payment.partial_credit(20)
          expect(payment).to be_completed
        end
      end
    end

    context "#save" do
      it "should call order#update!" do
        gateway.name = 'Gateway'
        gateway.distributors << create(:distributor_enterprise)
        gateway.save!

        order = create(:order)
        payment = Spree::Payment.create(:amount => 100, :order => order, :payment_method => gateway)
        order.should_receive(:update!)
        payment.save
      end

      context "when profiles are supported" do
        before do
          gateway.stub :payment_profiles_supported? => true
          payment.source.stub :has_payment_profile? => false
        end


        context "when there is an error connecting to the gateway" do
          it "should call gateway_error " do
            pending '[Spree build] Failing spec'
            message = double("gateway_error")
            connection_error = ActiveMerchant::ConnectionError.new(message, nil)
            expect(gateway).to receive(:create_profile).and_raise(connection_error)
            expect do
              Spree::Payment.create(
                :amount => 100,
                :order => order,
                :source => card,
                :payment_method => gateway
              )
            end.should raise_error(Spree::Core::GatewayError)
          end
        end

        context "when successfully connecting to the gateway" do
          it "should create a payment profile" do
            gateway.name = 'Gateway'
            gateway.distributors << create(:distributor_enterprise)
            gateway.save!

            payment.payment_method = gateway
            payment.source.save_requested_by_customer = true

            expect(gateway).to receive(:create_profile)

            Spree::Payment.create(
              :amount => 100,
              :order => create(:order),
              :source => card,
              :payment_method => gateway
            )
          end
        end


      end

      context "when profiles are not supported" do
        before { gateway.stub :payment_profiles_supported? => false }

        it "should not create a payment profile" do
          gateway.name = 'Gateway'
          gateway.distributors << create(:distributor_enterprise)
          gateway.save!

          gateway.should_not_receive :create_profile
          payment = Spree::Payment.create(
            :amount => 100,
            :order => create(:order),
            :source => card,
            :payment_method => gateway
          )
        end
      end
    end

    context "#build_source" do
      it "should build the payment's source" do
        params = { :amount => 100, :payment_method => gateway,
                   :source_attributes => {
          :expiry =>"1 / 99",
          :number => '1234567890123',
          :verification_value => '123'
        }
        }

        payment = Spree::Payment.new(params)
        expect(payment).to be_valid
        expect(payment.source).not_to be_nil
      end

      it "errors when payment source not valid" do
        params = { :amount => 100, :payment_method => gateway,
                   :source_attributes => {:expiry => "1 / 12" }}

        payment = Spree::Payment.new(params)
        expect(payment).not_to be_valid
        expect(payment.source).not_to be_nil
        expect(payment.source.errors[:number]).not_to be_empty
        expect(payment.source.errors[:verification_value]).not_to be_empty
      end
    end

    context "#currency" do
      before { order.stub(:currency) { "ABC" } }
      it "returns the order currency" do
        expect(payment.currency).to eq("ABC")
      end
    end

    context "#display_amount" do
      it "returns a Spree::Money for this amount" do
        expect(payment.display_amount).to eq(Spree::Money.new(payment.amount))
      end
    end

    # Regression test for #2216
    context "#gateway_options" do
      before { order.stub(:last_ip_address => "192.168.1.1") }

      it "contains an IP" do
        expect(payment.gateway_options[:ip]).to eq(order.last_ip_address)
      end
    end

    context "#set_unique_identifier" do
      # Regression test for #1998
      it "sets a unique identifier on create" do
        payment.run_callbacks(:save)
        expect(payment.identifier).not_to be_blank
        expect(payment.identifier.size).to eq(8)
        expect(payment.identifier).to be_a(String)
      end

      context "other payment exists" do
        let(:other_payment) {
          gateway.name = 'Gateway'
          gateway.distributors << create(:distributor_enterprise)
          gateway.save!

          payment = Spree::Payment.new
          payment.source = card
          payment.order = create(:order)
          payment.payment_method = gateway
          payment
        }

        before { other_payment.save! }

        it "doesn't set duplicate identifier" do
          payment.should_receive(:generate_identifier).and_return(other_payment.identifier)
          payment.should_receive(:generate_identifier).and_call_original

          payment.run_callbacks(:save)

          expect(payment.identifier).not_to be_blank
          expect(payment.identifier).not_to eq(other_payment.identifier)
        end
      end
    end

    describe "available actions" do
      context "for most gateways" do
        let(:payment) { create(:payment, source: create(:credit_card)) }

        it "can capture and void" do
          expect(payment.actions).to match_array %w(capture void)
        end

        describe "when a payment has been taken" do
          before do
            allow(payment).to receive(:state) { 'completed' }
            allow(payment).to receive(:order) { double(:order, payment_state: 'credit_owed') }
          end

          it "can void and credit" do
            expect(payment.actions).to match_array %w(void credit)
          end
        end
      end

      context "for Pin Payments" do
        let(:d) { create(:distributor_enterprise) }
        let(:pin) { Spree::Gateway::Pin.create! name: 'pin', distributor_ids: [d.id] }
        let(:payment) { create(:payment, source: create(:credit_card), payment_method: pin) }

        it "does not void" do
          expect(payment.actions).not_to include 'void'
        end

        describe "when a payment has been taken" do
          before do
            allow(payment).to receive(:state) { 'completed' }
            allow(payment).to receive(:order) { double(:order, payment_state: 'credit_owed') }
          end

          it "can refund instead of crediting" do
            expect(payment.actions).not_to include 'credit'
            expect(payment.actions).to     include 'refund'
          end
        end
      end
    end

    describe "refund!" do
      let(:payment) { create(:payment) }
      let(:success) { double(success?: true, authorization: 'abc123') }
      let(:failure) { double(success?: false) }

      it "always checks the environment" do
        allow(payment.payment_method).to receive(:refund) { success }
        expect(payment).to receive(:check_environment)
        payment.refund!
      end

      describe "calculating refund amount" do
        it "returns the parameter amount when given" do
          expect(payment.send(:calculate_refund_amount, 123)).to be === 123.0
        end

        it "refunds up to the value of the payment when the outstanding balance is larger" do
          allow(payment).to receive(:credit_allowed) { 123 }
          allow(payment).to receive(:order) { double(:order, outstanding_balance: 1000) }
          expect(payment.send(:calculate_refund_amount)).to eq(123)
        end

        it "refunds up to the outstanding balance of the order when the payment is larger" do
          allow(payment).to receive(:credit_allowed) { 1000 }
          allow(payment).to receive(:order) { double(:order, outstanding_balance: 123) }
          expect(payment.send(:calculate_refund_amount)).to eq(123)
        end
      end

      describe "performing refunds" do
        before do
          allow(payment).to receive(:calculate_refund_amount) { 123 }
          expect(payment.payment_method).to receive(:refund).and_return(success)
        end

        it "performs the refund without payment profiles" do
          allow(payment.payment_method).to receive(:payment_profiles_supported?) { false }
          payment.refund!
        end

        it "performs the refund with payment profiles" do
          allow(payment.payment_method).to receive(:payment_profiles_supported?) { true }
          payment.refund!
        end
      end

      it "records the response" do
        allow(payment).to receive(:calculate_refund_amount) { 123 }
        allow(payment.payment_method).to receive(:refund).and_return(success)
        expect(payment).to receive(:record_response).with(success)
        payment.refund!
      end

      it "records a payment on success" do
        allow(payment).to receive(:calculate_refund_amount) { 123 }
        allow(payment.payment_method).to receive(:refund).and_return(success)
        allow(payment).to receive(:record_response)

        expect do
          payment.refund!
        end.to change(Spree::Payment, :count).by(1)

        p = Spree::Payment.last
        expect(p.order).to eq(payment.order)
        expect(p.source).to eq(payment)
        expect(p.payment_method).to eq(payment.payment_method)
        expect(p.amount).to eq(-123)
        expect(p.response_code).to eq(success.authorization)
        expect(p.state).to eq('completed')
      end

      it "logs the error on failure" do
        allow(payment).to receive(:calculate_refund_amount) { 123 }
        allow(payment.payment_method).to receive(:refund).and_return(failure)
        allow(payment).to receive(:record_response)
        expect(payment).to receive(:gateway_error).with(failure)
        payment.refund!
      end
    end

    describe "applying transaction fees" do
      let!(:order) { create(:order) }
      let!(:line_item) { create(:line_item, order: order, quantity: 3, price: 5.00) }

      before do
        order.reload.update!
      end

      context "when order-based calculator" do
        let!(:shop) { create(:enterprise) }
        let!(:payment_method) { create(:payment_method, calculator: calculator) }
        let!(:calculator) do
          ::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)
        end

        context "when order complete" do
          let!(:order) { create(:completed_order_with_totals, distributor: shop) }
          let!(:variant) { order.line_items.first.variant }
          let!(:inventory_item) { create(:inventory_item, enterprise: shop, variant: variant) }

          it "creates adjustment" do
            payment = create(:payment, order: order, payment_method: payment_method,
                             amount: order.total)
            expect(payment.adjustment).to be_present
            expect(payment.adjustment.amount).not_to eq(0)
          end
        end
      end
    end
  end

  context 'OFN specs from previously decorated model' do
    describe "applying transaction fees" do
      let!(:order) { create(:order) }
      let!(:line_item) { create(:line_item, order: order, quantity: 3, price: 5.00) }

      before do
        order.reload.update!
      end

      context "to Stripe payments" do
        let(:shop) { create(:enterprise) }
        let(:payment_method) { create(:stripe_payment_method, distributor_ids: [create(:distributor_enterprise).id], preferred_enterprise_id: shop.id) }
        let(:payment) { create(:payment, order: order, payment_method: payment_method, amount: order.total) }
        let(:calculator) { ::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

        before do
          payment_method.calculator = calculator
          payment_method.save!

          allow(order).to receive(:pending_payments) { [payment] }
        end

        context "when the payment fails" do
          let(:failed_response) { ActiveMerchant::Billing::Response.new(false, "This is an error message") }

          before do
            allow(payment_method).to receive(:purchase) { failed_response }
          end

          it "makes the transaction fee ineligible and finalizes it" do
            # Decided to wrap the save process in order.process_payments!
            # since that is the context it is usually performed in
            order.process_payments!
            expect(order.payments.count).to eq 1
            expect(order.payments).to include payment
            expect(payment.state).to eq "failed"
            expect(payment.adjustment.eligible?).to be false
            expect(payment.adjustment.finalized?).to be true
            expect(order.adjustments.payment_fee.count).to eq 1
            expect(order.adjustments.payment_fee.eligible).to_not include payment.adjustment
          end
        end

        context "when the payment information is invalid" do
          before do
            allow(payment_method).to receive(:supports?) { false }
          end

          it "makes the transaction fee ineligible and finalizes it" do
            # Decided to wrap the save process in order.process_payments!
            # since that is the context it is usually performed in
            order.process_payments!
            expect(order.payments.count).to eq 1
            expect(order.payments).to include payment
            expect(payment.state).to eq "invalid"
            expect(payment.adjustment.eligible?).to be false
            expect(payment.adjustment.finalized?).to be true
            expect(order.adjustments.payment_fee.count).to eq 1
            expect(order.adjustments.payment_fee.eligible).to_not include payment.adjustment
          end
        end

        context "when the payment is processed successfully" do
          let(:successful_response) { ActiveMerchant::Billing::Response.new(true, "Yay!") }

          before do
            allow(payment_method).to receive(:purchase) { successful_response }
          end

          it "creates an appropriate adjustment" do
            # Decided to wrap the save process in order.process_payments!
            # since that is the context it is usually performed in
            order.process_payments!
            expect(order.payments.count).to eq 1
            expect(order.payments).to include payment
            expect(payment.state).to eq "completed"
            expect(payment.adjustment.eligible?).to be true
            expect(order.adjustments.payment_fee.count).to eq 1
            expect(order.adjustments.payment_fee.eligible).to include payment.adjustment
            expect(payment.adjustment.amount).to eq 1.5
          end
        end
      end
    end
  end
end
