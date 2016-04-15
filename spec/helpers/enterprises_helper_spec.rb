require 'spec_helper'

describe EnterprisesHelper do
  describe "loading available shipping methods" do

    context "when a FilterShippingMethods tag rule is in effect, with preferred visibility of 'visible'" do
      let!(:distributor) { create(:distributor_enterprise) }
      let!(:allowed_customer) { create(:customer, enterprise: distributor, tag_list: "local") }
      let!(:disallowed_customer) { create(:customer, enterprise: distributor, tag_list: "") }
      let!(:order) { create(:order, distributor: distributor) }
      let!(:tag_rule) { create(:filter_shipping_methods_tag_rule,
        enterprise: distributor,
        preferred_customer_tags: "local",
        preferred_shipping_method_tags: "local-delivery") }
      let!(:tagged_sm) { create(:shipping_method, require_ship_address: false, name: "Untagged", tag_list: "local-delivery") }
      let!(:untagged_sm) { create(:shipping_method, require_ship_address: false, name: "Tagged", tag_list: "") }

      before do
        distributor.shipping_methods = [tagged_sm, untagged_sm]
        allow(helper).to receive(:current_order) { order }
      end

      context "with a preferred visiblity of 'visible" do
        before { tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, 'visible') }

        context "when the customer is nil" do
          it "applies default action (hide)" do
            expect(helper.available_shipping_methods).to include untagged_sm
            expect(helper.available_shipping_methods).to_not include tagged_sm
          end
        end

        context "when the customer's tags match" do
          before { order.update_attribute(:customer_id, allowed_customer.id) }

          it "applies the action (show)" do
            expect(helper.available_shipping_methods).to include tagged_sm, untagged_sm
          end
        end

        context "when the customer's tags don't match" do
          before { order.update_attribute(:customer_id, disallowed_customer.id) }

          it "applies the default action (hide)" do
            expect(helper.available_shipping_methods).to include untagged_sm
            expect(helper.available_shipping_methods).to_not include tagged_sm
          end
        end
      end

      context "with a preferred visiblity of 'hidden" do
        before { tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, 'hidden') }

        context "when the customer is nil" do
          it "applies default action (show)" do
            expect(helper.available_shipping_methods).to include tagged_sm, untagged_sm
          end
        end

        context "when the customer's tags match" do
          before { order.update_attribute(:customer_id, allowed_customer.id) }

          it "applies the action (hide)" do
            expect(helper.available_shipping_methods).to include untagged_sm
            expect(helper.available_shipping_methods).to_not include tagged_sm
          end
        end

        context "when the customer's tags don't match" do
          before { order.update_attribute(:customer_id, disallowed_customer.id) }

          it "applies the default action (show)" do
            expect(helper.available_shipping_methods).to include tagged_sm, untagged_sm
          end
        end
      end
    end
  end
end
