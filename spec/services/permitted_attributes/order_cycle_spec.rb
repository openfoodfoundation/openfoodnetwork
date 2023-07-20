# frozen_string_literal: true

require 'spec_helper'

module PermittedAttributes
  describe OrderCycle do
    let(:oc_permitted_attributes) { PermittedAttributes::OrderCycle.new(params) }

    describe "with basic attributes" do
      let(:params) {
        ActionController::Parameters.new(order_cycle: { id: "2", name: "First Order Cycle" } )
      }

      it "keeps permitted and removes not permitted" do
        permitted_attributes = oc_permitted_attributes.call

        expect(permitted_attributes[:id]).to be nil
        expect(permitted_attributes[:name]).to eq "First Order Cycle"
      end
    end

    describe "nested incoming_exchanges attributes" do
      let(:params) {
        ActionController::Parameters.new(
          order_cycle: {
            incoming_exchanges: [
              {
                sender_id: "2",
                name: "Exchange Name",
                variants: []
              }
            ]
          }
        )
      }

      it "keeps permitted and removes not permitted" do
        permitted_attributes = oc_permitted_attributes.call

        exchange = permitted_attributes[:incoming_exchanges].first
        expect(exchange[:name]).to be nil
        expect(exchange[:sender_id]).to eq "2"
      end
    end

    describe "variants inside incoming_exchanges attributes" do
      let(:params) {
        ActionController::Parameters.new(
          order_cycle: {
            incoming_exchanges: [
              {
                variants: {
                  "7" => true,
                  "12" => true,
                }
              }
            ]
          }
        )
      }

      it "keeps all variant_ids provided" do
        permitted_attributes = oc_permitted_attributes.call

        exchange_variants = permitted_attributes[:incoming_exchanges].first[:variants]
        expect(exchange_variants["7"]).to be true
        expect(exchange_variants["12"]).to be true
      end
    end
  end
end
