# frozen_string_literal: true

require 'spec_helper'

describe VoucherAdjustmentsController, type: :controller do
  let(:user) { order.user }
  let(:address) { create(:address) }
  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:exchange) { order_cycle.exchanges.outgoing.first }
  let(:order) {
    create(:order_with_line_items, line_items_count: 1, distributor: distributor,
                                   order_cycle: order_cycle, bill_address: address,
                                   ship_address: address)
  }
  let(:payment_method) { distributor.payment_methods.first }
  let(:shipping_method) { distributor.shipping_methods.first }

  let(:voucher) { create(:voucher, code: 'some_code', enterprise: distributor) }

  before do
    exchange.variants << order.line_items.first.variant
    order.select_shipping_method shipping_method.id
    OrderWorkflow.new(order).advance_to_payment

    allow(controller).to receive(:current_order) { order }
    allow(controller).to receive(:spree_current_user) { user }
  end

  describe "#create" do
    describe "adding a voucher" do
      let(:params) { { voucher_code: voucher.code } }

      it "adds a voucher to the user's current order" do
        post :create, params: params

        expect(response.status).to eq(200)
        expect(order.reload.voucher_adjustments.length).to eq(1)
      end

      context "when voucher doesn't exist" do
        let(:params) { { voucher_code: "non_voucher" } }

        it "returns 422 and an error message" do
          post :create, params: params

          expect(response.status).to eq 422
          expect(flash[:error]).to match "Voucher Not found"
        end
      end

      context "when adding fails" do
        it "returns 422 and an error message" do
          # Create a non valid adjustment
          adjustment = build(:adjustment, label: nil)
          allow(voucher).to receive(:create_adjustment).and_return(adjustment)
          allow(Voucher).to receive(:find_by).and_return(voucher)

          post :create, params: params

          expect(response.status).to eq 422
          expect(flash[:error]).to match(
            "There was an error while adding the voucher and Label can't be blank"
          )
        end
      end
    end
  end

  describe "#destroy" do
    it "removes the voucher from the current order" do
      put :destroy, params: { id: voucher.id }

      expect(order.reload.voucher_adjustments.count).to eq 0
      expect(response.status).to eq 200
    end
  end
end
