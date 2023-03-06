# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::PaymentsController, type: :controller do
  let!(:shop) { create(:enterprise) }
  let!(:user) { shop.owner }
  let!(:order) { create(:order, distributor: shop, state: 'complete') }
  let!(:line_item) { create(:line_item, order: order, price: 5.0) }

  before do
    allow(controller).to receive(:spree_current_user) { user }
  end

  describe "#create" do
    let!(:payment_method) { create(:payment_method, distributors: [shop]) }
    let(:params) { { amount: order.total, payment_method_id: payment_method.id } }

    context "order is not complete" do
      let!(:order) do
        create(:order_with_totals_and_distribution, distributor: shop, state: "payment")
      end

      it "advances the order state" do
        expect {
          spree_post :create, payment: params, order_id: order.number
        }.to change { order.reload.state }.from("payment").to("complete")
      end
    end

    context "order is complete" do
      let!(:order) do
        create(:order_with_totals_and_distribution, distributor: shop,
                                                    state: "complete",
                                                    completed_at: Time.zone.now)
      end

      context "with Check payment (payment.process! does nothing)" do
        it "redirects to list of payments with success flash" do
          spree_post :create, payment: params, order_id: order.number

          redirects_to_list_of_payments_with_success_flash
          expect(order.reload.payments.last.state).to eq "checkout"
        end
      end

      context "with StripeSCA payment" do
        let!(:payment_method) { create(:stripe_sca_payment_method, distributors: [shop]) }

        context "where payment.authorize! raises GatewayError" do
          before do
            allow_any_instance_of(Spree::Payment).
              to receive(:authorize!).
              and_raise(Spree::Core::GatewayError.new("Stripe Authorization Failure"))
          end

          it "redirects to new payment page with flash error" do
            spree_post :create, payment: params, order_id: order.number

            redirects_to_new_payment_page_with_flash_error("Stripe Authorization Failure")
            expect(order.reload.payments.last.state).to eq "checkout"
          end
        end

        context "where payment.authorize! does not move payment to pending state" do
          before do
            allow_any_instance_of(Spree::Payment).to receive(:authorize!).and_return(true)
          end

          it "redirects to new payment page with flash error" do
            spree_post :create, payment: params, order_id: order.number

            redirects_to_new_payment_page_with_flash_error("Authorization Failure")
            expect(order.reload.payments.last.state).to eq "checkout"
          end
        end

        context "where further action is required" do
          before do
            allow_any_instance_of(Spree::Payment).to receive(:authorize!) do |payment|
              payment.update cvv_response_message: "https://www.stripe.com/authorize"
              payment.update state: "requires_authorization"
            end
          end
          it "redirects to new payment page with flash error" do
            spree_post :create, payment: params, order_id: order.number

            redirects_to_new_payment_page_with_flash_error('Action required')
          end
        end

        context "where both payment.process! and payment.authorize! work" do
          before do
            allow_any_instance_of(Spree::Payment).to receive(:authorize!) do |payment|
              payment.update state: "pending"
            end
            allow_any_instance_of(Spree::Payment).to receive(:process_offline!).and_return(true)
          end

          it "makes a payment with the provided card details" do
            source_attributes = {
              gateway_payment_profile_id: "pm_123",
              cc_type: "visa",
              last_digits: "4242",
              month: "4",
              year: "2100"
            }

            spree_post :create, payment: params.merge({ source_attributes: source_attributes }),
                                order_id: order.number

            payment = order.reload.payments.last
            expect(payment.source.attributes.transform_keys(&:to_sym)).to include source_attributes
          end

          it "redirects to list of payments with success flash" do
            spree_post :create, payment: params, order_id: order.number

            redirects_to_list_of_payments_with_success_flash
            expect(order.reload.payments.last.state).to eq "pending"
          end
        end
      end

      def redirects_to_list_of_payments_with_success_flash
        expect_redirect_to spree.admin_order_payments_url(order)
        expect(flash[:success]).to eq "Payment has been successfully created!"
      end

      def redirects_to_new_payment_page_with_flash_error(flash_error)
        expect_redirect_to spree.new_admin_order_payment_url(order)
        expect(flash[:error]).to eq flash_error
      end

      def expect_redirect_to(path)
        expect(response.status).to eq 302
        expect(response.location).to eq path
      end
    end
  end

  describe '#fire' do
    let(:payment_method) do
      create(
        :stripe_sca_payment_method,
        distributor_ids: [create(:distributor_enterprise).id],
        preferred_enterprise_id: create(:enterprise).id
      )
    end
    let(:order) { create(:order, state: 'complete') }
    let(:payment) do
      create(:payment, order: order, payment_method: payment_method, amount: order.total)
    end

    let(:successful_response) { ActiveMerchant::Billing::Response.new(true, "Yay!") }

    context 'on credit event' do
      let(:params) { { e: 'credit', order_id: order.number, id: payment.id } }

      before do
        request.env["HTTP_REFERER"] = "http://foo.com"
        allow(Spree::Payment).to receive(:find).with(payment.id.to_s) { payment }
      end

      it 'handles gateway errors' do
        allow(payment.payment_method)
          .to receive(:credit).and_raise(Spree::Core::GatewayError, 'error message')

        spree_put :fire, params

        expect(flash[:error]).to eq('error message')
        expect(response).to redirect_to('http://foo.com')
      end

      it 'handles validation errors' do
        allow(payment).to receive(:credit!).and_raise(StandardError, 'validation error')

        spree_put :fire, params

        expect(flash[:error]).to eq('validation error')
        expect(response).to redirect_to('http://foo.com')
      end

      it 'displays a success message and redirects to the referer' do
        allow(payment_method).to receive(:credit) { successful_response }

        spree_put :fire, params

        expect(flash[:success]).to eq('Payment Updated')
      end
    end

    context 'on refund event' do
      let(:params) { { e: 'refund', order_id: order.number, id: payment.id } }

      before do
        request.env["HTTP_REFERER"] = "http://foo.com"
        allow(Spree::Payment).to receive(:find).with(payment.id.to_s) { payment }
      end

      it 'handles gateway errors' do
        allow(payment.payment_method)
          .to receive(:refund).and_raise(Spree::Core::GatewayError, 'error message')

        spree_put :fire, params

        expect(flash[:error]).to eq('error message')
        expect(response).to redirect_to('http://foo.com')
      end

      it 'handles validation errors' do
        allow(payment).to receive(:refund!).and_raise(StandardError, 'validation error')

        spree_put :fire, params

        expect(flash[:error]).to eq('validation error')
        expect(response).to redirect_to('http://foo.com')
      end

      it 'displays a success message and redirects to the referer' do
        allow(payment_method).to receive(:refund) { successful_response }

        spree_put :fire, params

        expect(flash[:success]).to eq('Payment Updated')
      end
    end

    context 'on resend_authorization_email event' do
      let(:params) { { e: 'resend_authorization_email', order_id: order.number, id: payment.id } }
      let(:mail_mock) { double(:mailer_mock, deliver_later: true) }

      before do
        allow(PaymentMailer).to receive(:authorize_payment) { mail_mock }
        request.env["HTTP_REFERER"] = "http://foo.com"
        allow(Spree::Payment).to receive(:find).with(payment.id.to_s) { payment }
        allow(payment).to receive(:cvv_response_message).and_return("https://www.stripe.com/authorize")
        allow(payment).to receive(:requires_authorization?) { true }
      end

      it "resends the authorization email" do
        spree_put :fire, params

        expect(flash[:success]).to eq('Payment Updated')
        expect(PaymentMailer).to have_received(:authorize_payment)
        expect(mail_mock).to have_received(:deliver_later)
      end
    end

    context 'on an unrecognized event' do
      let(:params) { { e: 'unrecognized_event', order_id: order.number, id: payment.id } }

      before do
        request.env["HTTP_REFERER"] = "http://foo.com"
        allow(Spree::Payment).to receive(:find).with(payment.id.to_s) { payment }
      end

      it 'does not process the event' do
        spree_put :fire, params

        expect(payment).to_not receive(:unrecognized_event)
        expect(flash[:error]).to eq('Could not update the payment')
      end
    end
  end

  describe '#index' do
    context "order is canceled but has a completed payment" do
      let(:payment_method) do
        create(
          :stripe_sca_payment_method,
          distributor_ids: [create(:distributor_enterprise).id],
          preferred_enterprise_id: create(:enterprise).id
        )
      end
      let!(:order) { create(:order, state: 'canceled') }
      let!(:payment) do
        create(:payment, order: order, payment_method: payment_method, amount: order.total)
      end

      it "renders the payments tab" do
        spree_get :index, order_id: order.number
        expect(response.status).to eq 200
      end

      context "order is then resumed" do
        before do
          order.resume
        end

        it "still renders the payments tab" do
          spree_get :index, order_id: order.number
          expect(response.status).to eq 200
        end
      end
    end

    context "the order contains an item that is out of stock" do
      let!(:order) { create(:order_with_totals, distributor: shop, state: 'payment') }

      before do
        order.line_items.first.variant.update_attribute(:on_hand, 0)
      end

      it "redirects to the order details page" do
        spree_get :index, order_id: order.number
        expect(response.status).to eq 302
        expect(response.location).to eq spree.edit_admin_order_url(order)
      end
    end
  end
end
