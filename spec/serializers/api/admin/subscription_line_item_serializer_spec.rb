# frozen_string_literal: true

require 'spec_helper'

module Api
  module Admin
    describe SubscriptionLineItemSerializer do
      let(:subscription_line_item) { create(:subscription_line_item) }

      it "serializes a subscription line item with the product name" do
        serializer = described_class.new(subscription_line_item)

        expect(serializer.to_json).to match subscription_line_item.variant.product.name
      end

      context "when the variant of the subscription line item is soft deleted" do
        it "serializers the subscription line item with the product name" do
          subscription_line_item.variant.update_attribute :deleted_at, Time.zone.now

          serializer = described_class.new(subscription_line_item.reload)

          expect(serializer.to_json).to match subscription_line_item.variant.product.name
        end
      end
    end
  end
end
