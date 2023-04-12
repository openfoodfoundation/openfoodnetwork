# frozen_string_literal: true

require 'spec_helper'

describe VoucherAdjustmentsController, type: :request do
  let(:user) { order.user }
  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:order) { create( :order_with_line_items, line_items_count: 1, distributor: distributor) }
  let(:voucher) { Voucher.create(code: 'some_code', enterprise: distributor) }
  let!(:adjustment) { voucher.create_adjustment(voucher.code, order) }

  before do
    Flipper.enable(:split_checkout)

    # Make sure the order is created by the order user, the factory doesn't set ip properly
    order.created_by = user
    order.save!

    sign_in user
  end

  describe "DELETE voucher_adjustments/:id" do
    let(:cable_ready_header) { { accept: "text/vnd.cable-ready.json" } }

    context "with a cable ready request" do
      it "deletes the voucher adjustment" do
        delete("/voucher_adjustments/#{adjustment.id}", headers: cable_ready_header)

        expect(order.voucher_adjustments.length).to eq(0)
      end

      it "render a succesful response" do
        delete("/voucher_adjustments/#{adjustment.id}", headers: cable_ready_header)

        expect(response).to be_successful
      end

      context "when adjustment doesn't exits" do
        it "does nothing" do
          delete "/voucher_adjustments/-1", headers: cable_ready_header

          expect(order.voucher_adjustments.length).to eq(1)
        end

        it "render a succesful response" do
          delete "/voucher_adjustments/-1", headers: cable_ready_header

          expect(response).to be_successful
        end
      end
    end

    context "with an html request" do
      it "redirect to checkout payment step" do
        delete "/voucher_adjustments/#{adjustment.id}"

        expect(response).to redirect_to(checkout_step_path(:payment))
      end
    end
  end
end
