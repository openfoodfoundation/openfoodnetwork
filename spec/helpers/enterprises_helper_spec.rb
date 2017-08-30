require 'spec_helper'

describe EnterprisesHelper do
  let(:user) { create(:user) }
  let(:distributor) { create(:distributor_enterprise) }
  let(:some_other_distributor) { create(:distributor_enterprise) }

  before { allow(helper).to receive(:spree_current_user) { user } }

  describe "loading available shipping methods" do
    let!(:sm1) { create(:shipping_method, require_ship_address: false, distributors: [distributor]) }
    let!(:sm2) { create(:shipping_method, require_ship_address: false, distributors: [some_other_distributor]) }

    context "when the order has no current_distributor" do
      before do
        allow(helper).to receive(:current_distributor) { nil }
      end

      it "returns an empty array" do
        expect(helper.available_shipping_methods).to eq []
      end
    end

    context "when no tag rules are in effect" do
      before { allow(helper).to receive(:current_distributor) { distributor } }

      it "finds the shipping methods for the current distributor" do
        expect(helper.available_shipping_methods).to_not include sm2
        expect(helper.available_shipping_methods).to include sm1
      end
    end

    context "when FilterShippingMethods tag rules are in effect" do
      let(:customer) { create(:customer, user: user, enterprise: distributor) }
      let!(:tag_rule) { create(:filter_shipping_methods_tag_rule,
        enterprise: distributor,
        preferred_customer_tags: "local",
        preferred_shipping_method_tags: "local-delivery") }
      let!(:default_tag_rule) { create(:filter_shipping_methods_tag_rule,
        enterprise: distributor,
        is_default: true,
        preferred_shipping_method_tags: "local-delivery") }
      let!(:tagged_sm) { sm1 }
      let!(:untagged_sm) { sm2 }

      before do
        tagged_sm.update_attribute(:tag_list, 'local-delivery')
        distributor.shipping_methods = [tagged_sm, untagged_sm]
        allow(helper).to receive(:current_distributor) { distributor }
      end

      context "with a preferred visiblity of 'visible', default visibility of 'hidden'" do
        before { tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, 'visible') }
        before { default_tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, 'hidden') }

        context "when the customer is nil" do
          it "applies default action (hide)" do
            expect(helper.current_customer).to be nil
            expect(helper.available_shipping_methods).to include untagged_sm
            expect(helper.available_shipping_methods).to_not include tagged_sm
          end
        end

        context "when the customer's tags match" do
          before { customer.update_attribute(:tag_list, 'local') }

          it "applies the action (show)" do
            expect(helper.current_customer).to eq customer
            expect(helper.available_shipping_methods).to include tagged_sm, untagged_sm
          end
        end

        context "when the customer's tags don't match" do
          before { customer.update_attribute(:tag_list, 'something') }

          it "applies the default action (hide)" do
            expect(helper.current_customer).to eq customer
            expect(helper.available_shipping_methods).to include untagged_sm
            expect(helper.available_shipping_methods).to_not include tagged_sm
          end
        end
      end

      context "with a preferred visiblity of 'hidden', default visibility of 'visible'" do
        before { tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, 'hidden') }
        before { default_tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, 'visible') }

        context "when the customer is nil" do
          it "applies default action (show)" do
            expect(helper.current_customer).to be nil
            expect(helper.available_shipping_methods).to include tagged_sm, untagged_sm
          end
        end

        context "when the customer's tags match" do
          before { customer.update_attribute(:tag_list, 'local') }

          it "applies the action (hide)" do
            expect(helper.current_customer).to eq customer
            expect(helper.available_shipping_methods).to include untagged_sm
            expect(helper.available_shipping_methods).to_not include tagged_sm
          end
        end

        context "when the customer's tags don't match" do
          before { customer.update_attribute(:tag_list, 'something') }

          it "applies the default action (show)" do
            expect(helper.current_customer).to eq customer
            expect(helper.available_shipping_methods).to include tagged_sm, untagged_sm
          end
        end
      end
    end
  end

  describe "loading available payment methods" do
    let!(:pm1) { create(:payment_method, distributors: [distributor])}
    let!(:pm2) { create(:payment_method, distributors: [some_other_distributor])}

    context "when the order has no current_distributor" do
      before do
        allow(helper).to receive(:current_distributor) { nil }
      end

      it "returns an empty array" do
        expect(helper.available_payment_methods).to eq []
      end
    end

    context "when no tag rules are in effect" do
      before { allow(helper).to receive(:current_distributor) { distributor } }

      it "finds the payment methods for the current distributor" do
        expect(helper.available_payment_methods).to_not include pm2
        expect(helper.available_payment_methods).to include pm1
      end
    end

    context "when FilterPaymentMethods tag rules are in effect" do
      let(:customer) { create(:customer, user: user, enterprise: distributor) }
      let!(:tag_rule) { create(:filter_payment_methods_tag_rule,
        enterprise: distributor,
        preferred_customer_tags: "trusted",
        preferred_payment_method_tags: "trusted") }
      let!(:default_tag_rule) { create(:filter_payment_methods_tag_rule,
        enterprise: distributor,
        is_default: true,
        preferred_payment_method_tags: "trusted") }
      let(:tagged_pm) { pm1 }
      let(:untagged_pm) { pm2 }

      before do
        tagged_pm.update_attribute(:tag_list, 'trusted')
        distributor.payment_methods = [tagged_pm, untagged_pm]
        allow(helper).to receive(:current_distributor) { distributor }
      end

      context "with a preferred visiblity of 'visible', default visibility of 'hidden'" do
        before { tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, 'visible') }
        before { default_tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, 'hidden') }

        context "when the customer is nil" do
          it "applies default action (hide)" do
            expect(helper.current_customer).to be nil
            expect(helper.available_payment_methods).to include untagged_pm
            expect(helper.available_payment_methods).to_not include tagged_pm
          end
        end

        context "when the customer's tags match" do
          before { customer.update_attribute(:tag_list, 'trusted') }

          it "applies the action (show)" do
            expect(helper.current_customer).to eq customer
            expect(helper.available_payment_methods).to include tagged_pm, untagged_pm
          end
        end

        context "when the customer's tags don't match" do
          before { customer.update_attribute(:tag_list, 'something') }

          it "applies the default action (hide)" do
            expect(helper.current_customer).to eq customer
            expect(helper.available_payment_methods).to include untagged_pm
            expect(helper.available_payment_methods).to_not include tagged_pm
          end
        end
      end

      context "with a preferred visiblity of 'hidden', default visibility of 'visible'" do
        before { tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, 'hidden') }
        before { default_tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, 'visible') }

        context "when the customer is nil" do
          it "applies default action (show)" do
            expect(helper.current_customer).to be nil
            expect(helper.available_payment_methods).to include tagged_pm, untagged_pm
          end
        end

        context "when the customer's tags match" do
          before { customer.update_attribute(:tag_list, 'trusted') }

          it "applies the action (hide)" do
            expect(helper.current_customer).to eq customer
            expect(helper.available_payment_methods).to include untagged_pm
            expect(helper.available_payment_methods).to_not include tagged_pm
          end
        end

        context "when the customer's tags don't match" do
          before { customer.update_attribute(:tag_list, 'something') }

          it "applies the default action (show)" do
            expect(helper.current_customer).to eq customer
            expect(helper.available_payment_methods).to include tagged_pm, untagged_pm
          end
        end
      end
    end

    context "when StripeConnect payment methods are present" do
      let!(:pm3) { create(:payment_method, type: "Spree::Gateway::StripeConnect", distributors: [distributor])}
      before { allow(helper).to receive(:current_distributor) { distributor } }

      context "and Stripe Connect is disabled" do
        before { Spree::Config.set(stripe_connect_enabled: false) }

        it "ignores the Stripe payment method" do
          expect(helper.available_payment_methods.map(&:id)).to_not include pm3.id
        end
      end

      context "and Stripe Connect is enabled" do
        before do
          Spree::Config.set(stripe_connect_enabled: true)
          allow(Stripe).to receive(:publishable_key) { "some_key" }
        end

        it "includes the Stripe payment method" do
          expect(helper.available_payment_methods.map(&:id)).to include pm3.id
        end
      end
    end
  end
end
