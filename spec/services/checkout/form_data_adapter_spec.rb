# frozen_string_literal: true

require 'spec_helper'

describe Checkout::FormDataAdapter do
  describe '#params' do
    let(:params) { { "order" => { "order_id" => "123" } } }
    let(:order) { create(:order) }
    let(:user) { create(:user) }

    let(:adapter) { Checkout::FormDataAdapter.new(params, order, user) }

    it "returns the :order item in the params provided" do
      expect(adapter.params[:order]).to eq params["order"]
    end

    describe "when payment_attributes are provided" do
      before { params["order"]["payments_attributes"] = [{ "payment_method_id" => "123" }] }

      describe "and source attributes are provided" do
        let(:source_attributes) { { "payment_method_name" => "Pay at the farm" } }

        before { params["payment_source"] = { "123" => source_attributes } }

        it "moves payment source attributes to the order payment attributes" do
          expect(adapter.params[:order][:payments_attributes].
                   first[:source_attributes]).to eq source_attributes
        end
      end

      describe "and order total is not zero" do
        before { order.total = "50.0" }

        it "sets the payment attributes amount to the order total" do
          expect(adapter.params[:order][:payments_attributes].first[:amount]).to eq order.total
        end
      end

      describe "and a credit card is provided" do
        before do
          params["order"]["payments_attributes"].first["source_attributes"] =
            { "number" => "4444333322221111" }
        end

        it "fills in missing credit card brand" do
          expect(adapter.params[:order][:payments_attributes].first[:source_attributes][:cc_type]).to eq "visa"
        end

        it "leaves an existing credit card brand" do
          params["order"]["payments_attributes"].first["source_attributes"]["cc_type"] = "test"
          expect(adapter.params[:order][:payments_attributes].first[:source_attributes][:cc_type]).to eq "test"
        end

        it "doesn't touch the credit card brand without a number" do
          params["order"]["payments_attributes"].first["source_attributes"]["number"] = ""
          expect(adapter.params[:order][:payments_attributes].first[:source_attributes].key?(:cc_type)).to eq false
        end
      end

      describe "and existing credit card is provided" do
        before { params["order"]["existing_card_id"] = credit_card.id }

        describe "and credit card is owned by current user" do
          let(:credit_card) { create(:credit_card, user_id: user.id) }

          before { params["order"]["existing_card_id"] = credit_card.id }

          it "adds card details to payment attributes" do
            expect(adapter.params[:order][:payments_attributes].first[:source][:id]).to eq credit_card.id
            expect(adapter.params[:order][:payments_attributes].
                     first[:source][:last_digits]).to eq credit_card.last_digits
          end
        end

        describe "and credit card is not owned by current user" do
          let(:credit_card) { create(:credit_card) }

          it "raises exception if credit card provided doesnt belong to the current user" do
            expect { adapter.params[:order] }.to raise_error Spree::Core::GatewayError
          end
        end
      end
    end
  end
end
