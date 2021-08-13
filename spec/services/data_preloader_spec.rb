# frozen_string_literal: true

require "spec_helper"

describe DataPreloader do
  describe "#preload_enterprise_data" do
    let(:enterprise) { create(:enterprise) }

    context "when queries for given enterprises return no data" do
      it "sets appropriate default values for the preloaded data i.e. 0 for counts" do
        DataPreloader.preload_enterprise_data([enterprise])

        expect(enterprise.preloaded_data.enterprise_fees_count).to eq(0)
        expect(enterprise.preloaded_data.payment_methods_count).to eq(0)
        expect(enterprise.preloaded_data.producer_properties_count).to eq(0)
        expect(enterprise.preloaded_data.shipping_methods_count).to eq(0)
      end
    end

    context "when queries for given enterprises return some data" do
      before do
        create(:enterprise_fee, enterprise: enterprise)
        create(:producer_property, producer: enterprise, property: create(:property))
        create(:payment_method, distributors: [enterprise])
        create(:shipping_method, distributors: [enterprise])
      end

      it "sets the preloaded data on the given enterprises" do
        DataPreloader.preload_enterprise_data([enterprise])

        expect(enterprise.preloaded_data.enterprise_fees_count).to eq(1)
        expect(enterprise.preloaded_data.payment_methods_count).to eq(1)
        expect(enterprise.preloaded_data.producer_properties_count).to eq(1)
        expect(enterprise.preloaded_data.shipping_methods_count).to eq(1)
      end
    end
  end
end
