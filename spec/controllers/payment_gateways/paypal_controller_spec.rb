# frozen_string_literal: true

RSpec.describe PaymentGateways::PaypalController do
  context '#cancel' do
    it 'redirects back to checkout' do
      expect(get(:cancel)).to redirect_to checkout_path
    end
  end

  describe '#confirm' do
    let(:order) { create(:order_with_totals_and_distribution, state: "confirmation") }
    let(:payment_method) { create(:paypal_payment_method, distributors: [order.distributor]) }
    let(:payment) {
      create(:payment, state: "checkout", order:, amount: order.total, payment_method: )
    }

    before do
      order.update_order!
      order.payments << payment
      # Set the order id so the correct order is loaded
      session[:order_id] = order.id
      # We are not interested in completing the payment, so we just check it's called
      # and bypass the completion
      allow(controller).to receive(:process_payment_completion!)
    end

    it "updates pending paypal payment with token and payer id in the source" do
      token = "EC-XXXXXXXXXXXXXXXXX"
      payer_id = "ABCDEFGHIJ123"
      post :confirm, params: { payment_method_id: payment_method.id, token:, PayerID: payer_id }

      payment.reload
      expect(payment.source).to be_a(Spree::PaypalExpressCheckout)
      expect(payment.source.token).to eq(token)
      expect(payment.source.payer_id).to eq(payer_id)
    end

    it "resets the order" do
      mock_current_order

      post :confirm, params: { payment_method_id: payment_method.id }

      expect(controller.current_order).not_to eq(order)
    end

    it "sets the access token of the session" do
      mock_current_order

      post :confirm, params: { payment_method_id: payment_method.id }

      expect(session[:access_token]).to eq(controller.current_order.token)
    end

    context "when no pending paypal payment" do
      it "redirects to payment step with an error message" do
        # Mark paypal payment as failed
        order.payments.first.update(state: "failed")
        # Add a non paypal pending payment
        order.payments << create(:payment, state: "checkout", order: )

        expect(
          post(:confirm, params: { payment_method_id: payment_method.id })
        ).to redirect_to(checkout_step_path(step: :payment))
        expect(flash[:error]).to eq("No pending Paypal payment found")
      end
    end

    context "when the order cycle has closed" do
      let(:order_cycle) { order.order_cycle }
      let(:distributor) { order.distributor }

      it "redirects to shopfront with message if order cycle is expired" do
        allow(controller).to receive(:current_distributor).and_return(distributor)
        expect(controller).to receive(:current_order_cycle).and_return(order_cycle)
        expect(controller).to receive(:current_order).and_return(order).at_least(:once)
        expect(order_cycle).to receive(:closed?).and_return(true)
        expect(order).not_to receive(:empty!)
        expect(order).not_to receive(:assign_order_cycle!).with(nil)

        post :confirm, params: { payment_method_id: payment_method.id }

        message = "The order cycle you've selected has just closed. " \
                  "Please contact us to complete your order ##{order.number}!"

        expect(response).to redirect_to shops_url
        expect(flash[:info]).to eq(message)
      end
    end

    context "if the stock ran out whilst the payment was being placed" do
      it "redirects to the details page with out of stock error" do
        mock_order_check_stock_service(controller.current_order)

        post(:confirm, params: { payment_method_id: payment_method.id })

        expect(response).to redirect_to checkout_step_path(step: :details)

        # No payment has been completed
        expect(order.payments.completed.count).to eq 0
      end
    end

    context "when payment processing fails" do
      let(:current_order) { mock_current_order(completed: false) }

      before do
        expect(controller).to receive(:process_payment_completion!).and_call_original
      end

      it "redirects to checkout state path" do
        # Simulate payment failing
        expect(current_order).to receive(:process_payments!).and_return(false)

        expect(post(:confirm, params: { payment_method_id: payment_method.id })).
          to redirect_to checkout_step_path(step: :payment)

        expect(flash[:error]).to eq(
          'Payment could not be processed, please check the details you entered'
        )
      end

      it "logs the error" do
        # Simulate payment failing
        expect(current_order).to receive(:process_payments!).and_return(false)

        # redirect_to will also call Rails.logger.error
        allow(Rails.logger).to receive(:error)
        expect(Rails.logger).to receive(:error).with(
          "OrderCompletion#notify_failure: Payment could not be processed, " \
          "please check the details you entered"
        )
        expect(Alert).to receive(:raise_with_record)

        post(:confirm, params: { payment_method_id: payment_method.id })
      end

      context "with gateway error" do
        before do
          expect(current_order).to receive(:process_payments!).and_raise(
            Spree::Core::GatewayError.new("Connection issue")
          )
        end

        it "redirects to checkout details step" do
          expect(post(:confirm, params: { payment_method_id: payment_method.id })).
            to redirect_to checkout_step_path(step: :details)

          expect(flash[:error]).to eq(
            "There was a problem with your payment information: Connection issue"
          )
        end

        it "logs the error" do
          # redirect_to will also call Rails.logger.error
          allow(Rails.logger).to receive(:error)
          expect(Rails.logger).to receive(:error).with(
            "OrderCompletion#gateway_error: Connection issue"
          )
          expect(Alert).to receive(:raise_with_record).with(instance_of(Spree::Core::GatewayError),
                                                            Object)

          post(:confirm, params: { payment_method_id: payment_method.id })
        end
      end
    end
  end

  describe "#express" do
    let(:order) { create(:order_with_totals_and_distribution) }
    let(:response) { true }
    let(:provider_success_url) { "https://test.host/success" }
    let(:response_mock) { double(:response, success?: response, errors: [] ) }
    let(:provider_mock) {
      double(:provider, set_express_checkout: response_mock,
                        express_checkout_url: provider_success_url)
    }
    let(:payment_method) { create(:paypal_payment_method, distributors: [order.distributor]) }
    let(:payment_details_mock) { instance_double(Paypal::PaymentDetailsService) }

    before do
      allow(controller).to receive(:current_order) { order }
      allow(controller).to receive(:provider) { provider_mock }
      allow(provider_mock).to receive(:build_set_express_checkout)
      allow(Paypal::PaymentDetailsService).to receive(:new).with(
        order: order, address_required: false
      ).and_return(payment_details_mock)
      allow(payment_details_mock).to receive(:call).and_return({})
    end

    describe "request details" do
      it "creates a paypal express checkout data including payment details" do
        data = {
          SetExpressCheckoutRequestDetails: {
            InvoiceID: order.number,
            BuyerEmail: order.email,
            ReturnURL: String,
            CancelURL: String,
            SolutionType: "Mark",
            LandingPage: "Billing",
            cppheaderimage: "",
            NoShipping: 1,
            PaymentDetails: Array
          }
        }
        expect(provider_mock).to receive(:build_set_express_checkout).with(hash_including(data))

        post(:express, params: { payment_method_id: payment_method.id })
      end
    end

    context "when processing is successful" do
      it "redirects to a success URL generated by the payment provider" do
        expect(post(:express, params: { payment_method_id: payment_method.id }))
          .to redirect_to provider_success_url
      end
    end

    context "when processing fails" do
      let(:response) { false }

      it "redirects to checkout_step_path with a flash error" do
        expect(post(:express, params: { payment_method_id: payment_method.id }))
          .to redirect_to checkout_step_path(:payment)
        expect(flash[:error]).to eq "PayPal failed. "
      end

      it "logs the error" do
        # redirect_to will also call Rails.logger.error with the controller name
        expect(Rails.logger).to receive(:error).with(/PaypalController#express/).twice
        expect(Alert).to receive(:raise_with_record)

        post(:express, params: { payment_method_id: payment_method.id })
      end
    end

    context "when a SocketError is encountered during processing" do
      before do
        allow(response_mock).to receive(:success?).and_raise(SocketError)
      end

      it "redirects to checkout_step_path with a flash error" do
        expect(post(:express, params: { payment_method_id: payment_method.id }))
          .to redirect_to checkout_step_path(:payment)
        expect(flash[:error]).to eq "Could not connect to PayPal."
      end
    end

    context "when the order cycle has closed" do
      let(:order_cycle) { order.order_cycle }
      let(:distributor) { order.distributor }

      it "redirects to shopfront with message if order cycle is expired" do
        allow(controller).to receive(:current_distributor).and_return(distributor)
        expect(controller).to receive(:current_order_cycle).and_return(order_cycle)
        expect(controller).to receive(:current_order).and_return(order).at_least(:once)
        expect(order_cycle).to receive(:closed?).and_return(true)
        expect(order).not_to receive(:empty!)
        expect(order).not_to receive(:assign_order_cycle!).with(nil)

        post(:express)

        message = "The order cycle you've selected has just closed. " \
                  "Please contact us to complete your order ##{order.number}!"

        expect(response).to redirect_to shops_url
        expect(flash[:info]).to eq(message)
      end
    end

    context "when the stock ran out whilst the payment was being placed" do
      it "redirects to the details page with out of stock error" do
        mock_order_check_stock_service(controller.current_order)

        post(:express)

        expect(response).to redirect_to checkout_step_path(step: :details)
      end
    end
  end

  describe '#expire_current_order' do
    it 'empties the order_id of the session' do
      expect(session).to receive(:[]=).with(:order_id, nil)
      controller.__send__(:expire_current_order)
    end

    it 'resets the @current_order ivar' do
      controller.__send__(:expire_current_order)
      expect(controller.instance_variable_get(:@current_order)).to be_nil
    end
  end

  def mock_order_check_stock_service(order)
    check_stock_service_mock = instance_double(Orders::CheckStockService)
    expect(Orders::CheckStockService).to receive(:new).and_return(check_stock_service_mock)
    expect(check_stock_service_mock).to receive(:sufficient_stock?).and_return(false)
    expect(check_stock_service_mock).to receive(:update_line_items).and_return(order.variants)
  end

  def mock_current_order(completed: true)
    # Get the object loaded by the controller, so we can mock some method.
    # Using `order` won't work as it's not the object loaded by the controller eventhough it's
    # the same order
    current_order = controller.current_order(false)
    allow(current_order).to receive(:complete?).and_return(completed)
    allow(current_order).to receive(:checkout_allowed?).and_return(true)
    current_order
  end
end
