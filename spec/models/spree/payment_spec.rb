# frozen_string_literal: true

RSpec.describe Spree::Payment do
  before do
    # mock the call with "ofn.payment_transition" so we don't call the related listener and services
    allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
    allow(ActiveSupport::Notifications).to receive(:instrument)
      .with("ofn.payment_transition", any_args).and_return(nil)
  end

  context 'original specs from Spree' do
    before { Stripe.api_key = "sk_test_12345" }
    let(:order) { create(:order) }
    let(:shop) { create(:enterprise) }
    let(:payment_method) {
      payment_method = create(:stripe_sca_payment_method,
                              distributor_ids: [create(:distributor_enterprise).id],
                              preferred_enterprise_id: shop.id)
      allow(payment_method).to receive(:source_required) { true }
      allow(payment_method).to receive(:payment) { true }
      payment_method
    }

    let(:card) {
      create(:credit_card)
    }

    let(:payment) do
      payment = create(:payment)
      payment.source = card
      payment.order = order
      payment.payment_method = payment_method
      payment.response_code = "12345"
      payment
    end

    let(:amount_in_cents) { payment.amount.to_f * 100 }

    let(:success_response) do
      instance_double(
        ActiveMerchant::Billing::Response,
        authorization: "123",
        success?: true,
        avs_result: { 'code' => 'avs-code' },
        cvv_result: { code: nil, message: nil }
      )
    end
    let(:failed_response) { instance_double(ActiveMerchant::Billing::Response, success?: false) }

    context "extends LocalizedNumber" do
      subject { build_stubbed(:payment) }
      it_behaves_like "a model using the LocalizedNumber module", [:amount]
    end

    context 'validations' do
      it "returns useful error messages when source is invalid" do
        payment = build_stubbed(:payment, source: Spree::CreditCard.new)
        expect(payment).not_to be_valid
        cc_errors = payment.errors['Credit Card']
        expect(cc_errors).to include("Number can't be blank")
        expect(cc_errors).to include("Month is not a number")
        expect(cc_errors).to include("Year is not a number")
        expect(cc_errors).to include("Verification Value can't be blank")
      end
    end

    context "creating a new payment alongside other incomplete payments" do
      let(:order) { create(:order_with_totals) }
      let!(:incomplete_payment) { create(:payment, order:, state: "pending") }
      let(:new_payment) { create(:payment, order:, state: "checkout") }

      it "invalidates other incomplete payments on the order" do
        new_payment

        expect(incomplete_payment.reload.state).to eq "invalid"
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
        allow(payment).to receive(:record_response)
        allow(card).to receive(:has_payment_profile?).and_return(true)
        allow(payment).to receive(:update_order).and_return(true)
        allow(payment).to receive(:create_payment_profile).and_return(true)
      end

      context "#process!" do
        it "should call purchase!" do
          payment = build_stubbed(:payment, payment_method:)
          expect(payment).to receive(:purchase!)
          payment.process!
        end

        it "should make the state 'processing'" do
          allow(payment_method).to receive(:capture).and_return(success_response)
          allow(payment_method).to receive(:purchase).and_return(success_response)

          expect(payment).to receive(:started_processing!)

          payment.save!
          payment.process!
        end

        it "should invalidate if payment method doesnt support source" do
          expect(payment.payment_method).to receive(:supports?)
            .with(payment.source).and_return(false)
          expect { payment.process! }.to raise_error(Spree::Core::GatewayError)
          expect(payment.state).to eq('invalid')
        end

        context "the payment is already authorized" do
          before do
            allow(payment).to receive(:response_code) { "pi_123" }
          end

          it "should call purchase" do
            expect(payment).to receive(:purchase!)
            payment.process!
          end
        end
      end

      context "#process_offline when payment is already authorized" do
        before do
          allow(payment).to receive(:response_code) { "pi_123" }
        end

        it "should call capture if the payment is already authorized" do
          expect(payment).to receive(:capture!)
          expect(payment).not_to receive(:purchase!)
          payment.process_offline!
        end
      end

      context "#authorize" do
        before do
          allow(payment_method).to receive(:authorize) { success_response }
        end

        it "should call authorize on the gateway with the payment amount" do
          expect(payment.payment_method).to receive(:authorize).with(
            amount_in_cents, card, anything
          ).and_return(success_response)
          payment.authorize!
        end

        it "should call authorize on the gateway with the currency code" do
          allow(payment).to receive(:currency) { "GBP" }
          expect(payment.payment_method).to receive(:authorize).with(
            amount_in_cents, card, hash_including({ currency: "GBP" })
          ).and_return(success_response)
          payment.authorize!
        end

        it "should log the response" do
          payment.authorize!
          expect(payment).to have_received(:record_response)
        end

        context "when gateway does not match the environment" do
          it "should raise an exception" do
            allow(payment_method).to receive(:environment) { "foo" }
            expect { payment.authorize! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "if successful" do
          before do
            expect(payment.payment_method).to receive(:authorize).with(
              amount_in_cents, card, anything
            ).and_return(success_response)
          end

          it "should store the response_code, avs_response and cvv_response fields" do
            payment.authorize!
            expect(payment.response_code).to eq('123')
            expect(payment.avs_response).to eq('avs-code')
          end

          it "should make payment pending" do
            expect(payment).to receive(:pend!)
            payment.authorize!
          end
        end

        context "authorization is required" do
          before do
            allow(success_response).to receive(:cvv_result) {
              { 'code' => nil,
                'message' => nil,
                'redirect_auth_url' => "https://stripe.com/redirect" }
            }
            expect(payment.payment_method).to receive(:authorize).with(
              amount_in_cents, card, anything
            ).and_return(success_response)
          end

          it "should move the payment to requires_authorization" do
            expect(payment).to receive(:require_authorization!)
            payment.authorize!
          end
        end

        context "if unsuccessful" do
          it "should mark payment as failed" do
            allow(payment_method).to receive(:authorize).and_return(failed_response)
            expect(payment).to receive(:failure)
            expect(payment).not_to receive(:pend)
            expect {
              payment.authorize!
            }.to raise_error(Spree::Core::GatewayError)
          end
        end
      end

      context "purchase" do
        before do
          allow(payment_method).to receive(:purchase).and_return(success_response)
        end

        it "should call purchase on the gateway with the payment amount" do
          expect(payment_method).to receive(:purchase).with(amount_in_cents, card,
                                                            anything).and_return(success_response)
          payment.purchase!
        end

        it "should log the response" do
          payment.purchase!
          expect(payment).to have_received(:record_response)
        end

        context "when gateway does not match the environment" do
          it "should raise an exception" do
            allow(payment_method).to receive(:environment) { "foo" }
            expect { payment.purchase! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "if successful" do
          before do
            expect(payment.payment_method).to receive(:purchase).with(
              amount_in_cents, card, anything
            ).and_return(success_response)
          end

          it "should store the response_code and avs_response" do
            payment.purchase!
            expect(payment.response_code).to eq('123')
            expect(payment.avs_response).to eq('avs-code')
          end

          it "should make payment complete" do
            expect(payment).to receive(:complete!)
            payment.purchase!
          end
        end

        context "if unsuccessful" do
          it "should make payment failed" do
            allow(payment_method).to receive(:purchase).and_return(failed_response)
            expect(payment).to receive(:failure)
            expect(payment).not_to receive(:pend)
            expect { payment.purchase! }.to raise_error(Spree::Core::GatewayError)
          end
        end
      end

      context "#capture" do
        before do
          allow(payment).to receive(:complete).and_return(true)
        end

        context "when payment is pending" do
          before do
            payment.state = 'pending'
          end

          context "if successful" do
            before do
              expect(payment.payment_method).to receive(:capture).and_return(success_response)
            end

            it "should make payment complete" do
              expect(payment).to receive(:complete)
              payment.capture!
            end

            it "should store the response_code" do
              allow(payment_method).to receive(:capture).and_return(success_response)
              payment.capture!
              expect(payment.response_code).to eq('123')
            end
          end

          context "if unsuccessful" do
            it "should not make payment complete" do
              allow(payment_method).to receive(:capture).and_return(failed_response)
              expect(payment).to receive(:failure)
              expect(payment).not_to receive(:complete)
              expect { payment.capture! }.to raise_error(Spree::Core::GatewayError)
            end
          end
        end

        # Regression test for #2119
        context "when payment is completed" do
          it "should do nothing" do
            payment = build_stubbed(:payment, :completed)
            expect(payment).not_to receive(:complete)
            expect(payment.payment_method).not_to receive(:capture)
            expect(payment.log_entries).not_to receive(:create)
            payment.capture!
          end
        end
      end

      context "#void" do
        before do
          payment.response_code = '123'
          payment.state = 'pending'

          allow(payment_method).to receive(:void).and_return(success_response)
        end

        it "should log the response" do
          payment.void_transaction!
          expect(payment).to have_received(:record_response)
        end

        context "when payment_method does not match the environment" do
          it "should raise an exception" do
            payment = build_stubbed(:payment, payment_method:)
            allow(payment_method).to receive(:environment) { "foo" }
            expect { payment.void_transaction! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "if successful" do
          it "should update the response_code with the authorization from the gateway" do
            payment.response_code = 'abc'
            payment.void_transaction!

            expect(payment.response_code).to eq('123')
          end
        end

        context "if unsuccessful" do
          it "should not void the payment" do
            allow(payment_method).to receive(:void).and_return(failed_response)
            expect(payment).not_to receive(:void)
            expect { payment.void_transaction! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        # Regression test for #2119
        context "if payment is already voided" do
          it "should not void the payment" do
            payment = build_stubbed(:payment, payment_method:, state: 'void')
            expect(payment.payment_method).not_to receive(:void)
            payment.void_transaction!
          end
        end

        context "if payment has any adjustment" do
          let!(:order) { create(:order) }
          let!(:payment_method) {
            create(:payment_method, calculator: Calculator::FlatRate.new(preferred_amount: 10))
          }

          it "should create another adjustment and revoke the previous one" do
            payment = create(:payment, order:, payment_method:)
            expect(order.all_adjustments.payment_fee.eligible.length).to eq(1)

            payment.void_transaction!
            expect(order.all_adjustments.payment_fee.eligible.length).to eq(0)

            payment = create(:payment, order:, payment_method:)
            expect(order.all_adjustments.payment_fee.eligible.length).to eq(1)
          end
        end
      end

      describe "#credit" do
        before do
          payment.state = 'completed'
          payment.response_code = '123'

          # Stub payment.method#credit
          allow(payment_method).to receive(:credit).and_return(success_response)
        end

        context "when outstanding_balance is less than payment amount" do
          before do
            allow(payment.order).to receive(:outstanding_balance) { 10 }
            allow(payment).to receive(:credit_allowed) { 1000 }
          end

          it "should call credit on the gateway with the credit amount and response_code" do
            expect(payment_method).to receive(:credit).with(1000, '123',
                                                            anything).and_return(success_response)
            payment.credit!
          end
        end

        context "if payment method has any payment fees" do
          before do
            expect(payment.order).to receive(:outstanding_balance).at_least(:once) { 10 }
            expect(payment).to receive(:credit_allowed) { 200 }
          end

          it "should not applied any transaction fees" do
            payment.credit!
            expect(payment.adjustment.finalized?).to eq(false)
            expect(order.all_adjustments.payment_fee.length).to eq(0)
          end
        end

        context "when outstanding_balance is equal to payment amount" do
          before do
            allow(payment.order).to receive(:outstanding_balance) { payment.amount }
          end

          it "should call credit on the gateway with the credit amount and response_code" do
            expect(payment_method).to receive(:credit).with(
              amount_in_cents, '123', anything
            ).and_return(success_response)
            payment.credit!
          end
        end

        context "when outstanding_balance is greater than payment amount" do
          before do
            allow(payment.order).to receive(:outstanding_balance) { 101 }
          end

          it "should call credit on the gateway with original payment amount and response_code" do
            expect(payment_method).to receive(:credit).with(
              amount_in_cents.to_f, '123', anything
            ).and_return(success_response)
            payment.credit!
          end
        end

        context "when amount <= credit_allowed" do
          it "makes the state processing" do
            payment.payment_method.name = 'Gateway'
            payment.payment_method.distributors << create(:distributor_enterprise)
            payment.payment_method.save!

            payment.order = create(:order)

            payment.state = 'completed'
            allow(payment).to receive(:credit_allowed) { 10 }
            payment.partial_credit(10)
            expect(payment).to be_processing
          end

          it "calls credit on the source with the payment and amount" do
            payment.state = 'completed'
            allow(payment).to receive(:credit_allowed) { 10 }
            expect(payment).to receive(:credit!).with(10)
            payment.partial_credit(10)
          end
        end

        context "when amount > credit_allowed" do
          it "should not call credit on the source" do
            payment = build_stubbed(:payment)
            payment.state = 'completed'
            allow(payment).to receive(:credit_allowed) { 10 }
            payment.partial_credit(20)
            expect(payment).to be_completed
          end
        end

        it "should log the response" do
          payment.credit!
          expect(payment).to have_received(:record_response)
        end

        context "when gateway does not match the environment" do
          it "should raise an exception" do
            payment = build_stubbed(:payment, payment_method:)
            allow(payment_method).to receive(:environment) { "foo" }
            expect { payment.credit! }.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "when response is successful" do
          it "should create an offsetting payment" do
            expect(Spree::Payment).to receive(:create!)
            payment.credit!
          end

          it "resulting payment should have correct values" do
            allow(payment.order).to receive(:new_outstanding_balance) { 100 }
            allow(payment).to receive(:credit_allowed) { 10 }

            offsetting_payment = payment.credit!
            expect(offsetting_payment.amount.to_f).to eq(-10)
            expect(offsetting_payment).to be_completed
            expect(offsetting_payment.response_code).to eq('123')
            expect(offsetting_payment.source).to eq(payment)
          end

          context 'and the source payment card is expired' do
            let(:card) do
              Spree::CreditCard.new(month: 12, year: 1995, number: '4111111111111111',
                                    verification_value: '123')
            end

            it 'lets the new payment to be saved' do
              allow(payment.order).to receive(:new_outstanding_balance) { 100 }
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
        allow(payment_method).to receive(:credit).and_return(failed_response)
        expect(Spree::Payment).not_to receive(:create)
        expect { payment.credit! }.to raise_error(Spree::Core::GatewayError)
      end
    end

    context "when already processing" do
      it "should return nil without trying to process the source" do
        payment = build_stubbed(:payment)
        payment.state = 'processing'

        expect(payment).not_to receive(:authorize!)
        expect(payment).not_to receive(:purchase!)
        expect(payment.process!).to be_nil
      end
    end

    context "with source required" do
      context "raises an error if no source is specified" do
        specify do
          payment = build_stubbed(:payment, source: nil, payment_method:)
          expect {
            payment.process!
          }.to raise_error(Spree::Core::GatewayError, Spree.t(:payment_processing_failed))
        end
      end
    end

    context "with source optional" do
      context "raises no error if source is not specified" do
        specify do
          payment = build_stubbed(:payment, source: nil, payment_method:)
          allow(payment.payment_method).to receive(:source_required?) { false }
          expect { payment.process! }.not_to raise_error
        end
      end
    end

    context "#credit_allowed" do
      it "is the difference between offsets total and payment amount" do
        payment = build_stubbed(:payment, amount: 100)
        allow(payment).to receive(:offsets_total) { 0 }
        expect(payment.credit_allowed).to eq(100)
        allow(payment).to receive(:offsets_total) { 80 }
        expect(payment.credit_allowed).to eq(20)
      end
    end

    context "#save" do
      context "completed payments" do
        it "updates order payment total" do
          payment = create(:payment, :completed, amount: 100, order:)
          expect(order.payment_total).to eq payment.amount
        end
      end

      context "non-completed payments" do
        it "doesn't update order payment total" do
          expect {
            create(:payment, amount: 100, order:)
          }.not_to change { order.payment_total }
        end
      end

      context 'when the payment was completed but now void' do
        let(:payment) { create(:payment, :completed, amount: 100, order:) }

        it 'updates order payment total' do
          payment.void
          expect(order.payment_total).to eq 0
        end
      end

      context "completed orders" do
        let(:order_updater) { OrderManagement::Order::Updater.new(order) }

        before { allow(order).to receive(:completed?) { true } }

        it "updates payment_state and shipments" do
          expect(OrderManagement::Order::Updater).to receive(:new).with(order).
            and_return(order_updater)

          expect(order_updater).to receive(:after_payment_update).with(kind_of(Spree::Payment)).
            and_call_original

          expect(order_updater).to receive(:update_payment_state)
          expect(order_updater).to receive(:update_shipment_state)
          create(:payment, amount: 100, order:)
        end
      end

      context "when profiles are supported" do
        before do
          allow(payment.source).to receive(:has_payment_profile?) { false }
        end

        context "when there is an error connecting to the gateway" do
          it "should call gateway_error " do
            pending '[Spree build] Failing spec'
            message = double("gateway_error")
            connection_error = ActiveMerchant::ConnectionError.new(message, nil)
            expect(payment_method).to receive(:create_profile).and_raise(connection_error)
            expect do
              Spree::Payment.create(
                amount: 100,
                order:,
                source: card,
                payment_method:
              )
            end.to raise_error(Spree::Core::GatewayError)
          end
        end

        context "when successfully connecting to the gateway" do
          it "should create a payment profile" do
            payment_method.name = 'Gateway'
            payment_method.distributors << create(:distributor_enterprise)
            payment_method.save!

            payment.payment_method = payment_method
            payment.source.save_requested_by_customer = true

            expect(payment_method).to receive(:create_profile)

            Spree::Payment.create(
              amount: 100,
              order: create(:order),
              source: card,
              payment_method:
            )
          end
        end
      end

      context "when profiles are not supported" do
        it "should not create a payment profile" do
          payment_method.name = 'Gateway'
          payment_method.distributors << create(:distributor_enterprise)
          payment_method.save!

          expect(payment_method).not_to receive :create_profile
          payment = Spree::Payment.create(
            amount: 100,
            order: create(:order),
            source: card,
            payment_method:
          )
        end
      end

      context 'when the payment was completed but now void' do
        let(:payment) { create(:payment, :completed, amount: 100, order:) }

        it 'updates order payment total' do
          payment.void
          expect(order.payment_total).to eq 0
        end
      end
    end

    context "#build_source" do
      it "should build the payment's source" do
        params = { amount: 100, payment_method:,
                   source_attributes: {
                     expiry: "1 / 99",
                     number: '1234567890123',
                     verification_value: '123'
                   } }

        payment = Spree::Payment.new(params)
        expect(payment).to be_valid
        expect(payment.source).not_to be_nil
      end

      it "errors when payment source not valid" do
        params = { amount: 100, payment_method:,
                   source_attributes: { expiry: "1 / 12" } }

        payment = Spree::Payment.new(params)
        expect(payment).not_to be_valid
        expect(payment.source).not_to be_nil
        expect(payment.source.errors[:number]).not_to be_empty
        expect(payment.source.errors[:verification_value]).not_to be_empty
      end
    end

    context "#currency" do
      it "returns the order currency" do
        payment = build_stubbed(:payment, order: build_stubbed(:order, currency: "ABC"))
        expect(payment.currency).to eq("ABC")
      end
    end

    context "#display_amount" do
      it "returns a Spree::Money for this amount" do
        payment = build_stubbed(:payment)
        expect(payment.display_amount).to eq(Spree::Money.new(payment.amount))
      end
    end

    # Regression test for #2216
    context "#gateway_options" do
      before do
        allow(order).to receive(:last_ip_address) { "192.168.1.1" }
      end

      it "contains an IP" do
        expect(payment.gateway_options[:ip]).to eq(order.last_ip_address)
      end
    end

    context "#set_unique_identifier" do
      # Regression test for Spree #1998
      it "sets a unique identifier on create" do
        payment.run_callbacks(:create)
        expect(payment.identifier).not_to be_blank
        expect(payment.identifier.size).to eq(8)
        expect(payment.identifier).to be_a(String)
      end

      # Regression test for Spree #3733
      it "does not regenerate the identifier on re-save" do
        payment.save
        old_identifier = payment.identifier
        payment.save
        expect(payment.identifier).to eq old_identifier
      end

      context "other payment exists" do
        let(:other_payment) {
          payment_method.name = 'Gateway'
          payment_method.distributors << create(:distributor_enterprise)
          payment_method.save!

          payment = Spree::Payment.new
          payment.source = card
          payment.order = create(:order)
          payment.payment_method = payment_method
          payment
        }

        before { other_payment.save! }

        it "doesn't set duplicate identifier" do
          allow(payment).to receive(:generate_identifier).and_return(other_payment.identifier)
          allow(payment).to receive(:generate_identifier).and_call_original

          payment.run_callbacks(:create)

          expect(payment.identifier).not_to be_blank
          expect(payment.identifier).not_to eq(other_payment.identifier)
        end
      end
    end

    describe "available actions" do
      context "for most gateways" do
        let(:payment) { build_stubbed(:payment, source: build_stubbed(:credit_card)) }

        it "can capture and void" do
          expect(payment.actions).to match_array %w(capture_and_complete_order void)
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
        let(:payment) { build_stubbed(:payment) }

        it "returns the parameter amount when given" do
          expect(payment.__send__(:calculate_refund_amount, 123)).to eq(123)
        end

        it "refunds up to the value of the payment when the outstanding balance is larger" do
          allow(payment).to receive(:credit_allowed) { 123 }
          allow(payment).to receive(:order) { double(:order, outstanding_balance: 1000) }
          expect(payment.__send__(:calculate_refund_amount)).to eq(123)
        end

        it "refunds up to the outstanding balance of the order when the payment is larger" do
          allow(payment).to receive(:credit_allowed) { 1000 }
          allow(payment).to receive(:order) { double(:order, outstanding_balance: 123) }
          expect(payment.__send__(:calculate_refund_amount)).to eq(123)
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
        end.to change { Spree::Payment.count }.by(1)

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
      let!(:line_item) { create(:line_item, order:, quantity: 3, price: 5.00) }

      before do
        order.reload.update_order!
      end

      context "when order-based calculator" do
        let!(:shop) { create(:enterprise) }
        let!(:payment_method) { create(:payment_method, calculator:) }
        let!(:calculator) do
          Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)
        end

        context "when order complete" do
          let!(:order) { create(:completed_order_with_totals, distributor: shop) }
          let!(:variant) { order.line_items.first.variant }
          let!(:inventory_item) { create(:inventory_item, enterprise: shop, variant:) }

          it "creates adjustment" do
            payment = create(:payment, order:, payment_method:,
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
      let!(:line_item) { create(:line_item, order:, quantity: 3, price: 5.00) }

      before do
        order.reload.update_order!
      end

      context "to Stripe payments" do
        let(:shop) { create(:enterprise) }
        let(:payment_method) {
          create(:stripe_sca_payment_method, distributor_ids: [create(:distributor_enterprise).id],
                                             preferred_enterprise_id: shop.id)
        }
        let(:payment) {
          create(:payment, order:, payment_method:, amount: order.total)
        }
        let(:calculator) { Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

        before do
          payment_method.calculator = calculator
          payment_method.save!

          allow(order).to receive(:pending_payments) { [payment] }
        end

        context "when the payment fails" do
          let(:failed_response) {
            ActiveMerchant::Billing::Response.new(false, "This is an error message")
          }

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
            expect(order.all_adjustments.payment_fee.count).to eq 1
            expect(order.all_adjustments.payment_fee.eligible).not_to include payment.adjustment
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
            expect(order.all_adjustments.payment_fee.count).to eq 1
            expect(order.all_adjustments.payment_fee.eligible).not_to include payment.adjustment
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
            expect(order.all_adjustments.payment_fee.count).to eq 1
            expect(order.all_adjustments.payment_fee.eligible).to include payment.adjustment
            expect(payment.adjustment.amount).to eq 1.5
          end
        end
      end
    end
  end

  describe "#clear_authorization_url" do
    let(:payment) { create(:payment, redirect_auth_url: "auth_url") }

    it "removes the redirect_auth_url" do
      payment.clear_authorization_url
      expect(payment.redirect_auth_url).to eq(nil)
    end
  end

  describe "#complete" do
    let(:payment) { build(:payment, state: "processing") }

    it "sets :captured_at to the current time" do
      payment.complete
      expect(payment.captured_at).to be_present
    end
  end

  describe "payment transition" do
    it "notifies of payment status change" do
      payment = create(:payment)

      allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
      expect(ActiveSupport::Notifications).to receive(:instrument).with(
        "ofn.payment_transition", payment: payment, event: "processing"
      )

      payment.started_processing!
    end
  end
end
