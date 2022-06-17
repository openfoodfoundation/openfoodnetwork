# frozen_string_literal: true

require 'spec_helper'

describe OrderAvailableShippingMethods do
  context "when the order has no current_distributor" do
    it "returns an empty array" do
      order_cycle = create(:sells_own_order_cycle)
      order = build(:order, distributor: nil, order_cycle: order_cycle)

      expect(OrderAvailableShippingMethods.new(order).to_a).to eq []
    end
  end

  it "does not return 'back office only' shipping method" do
    distributor = create(:distributor_enterprise)
    frontend_shipping_method = create(:shipping_method, distributors: [distributor])
    backoffice_only_shipping_method = create(:shipping_method,
                                             distributors: [distributor], display_on: 'back_end')
    order_cycle = create(:sells_own_order_cycle)
    order = build(:order, distributor: distributor, order_cycle: order_cycle)

    available_shipping_methods = OrderAvailableShippingMethods.new(order).to_a

    expect(available_shipping_methods).to eq [frontend_shipping_method]
  end

  context "when no tag rules are in effect" do
    context "sells own order cycle i.e. simple" do
      it "only returns the shipping methods which are available on the order cycle
          and belong to the order distributor" do
        distributor_i = create(:distributor_enterprise)
        distributor_ii = create(:distributor_enterprise)
        distributor_iii = create(:distributor_enterprise)
        shipping_method_i = create(:shipping_method, distributors: [distributor_i])
        shipping_method_ii = create(:shipping_method, distributors: [distributor_ii])
        shipping_method_iii = create(:shipping_method, distributors: [distributor_iii])
        order_cycle = create(:sells_own_order_cycle, distributors: [distributor_i, distributor_ii])
        order = build(:order, distributor: distributor_i, order_cycle: order_cycle)

        available_shipping_methods = OrderAvailableShippingMethods.new(order).to_a

        expect(available_shipping_methods).to eq [shipping_method_i]
      end
    end

    context "distributor order cycle i.e. not simple" do
      it "only returns the shipping methods which are available on the order cycle
          and belong to the order distributor" do
        distributor_i = create(:distributor_enterprise)
        distributor_ii = create(:distributor_enterprise)
        shipping_method_i = create(:shipping_method, distributors: [distributor_i])
        shipping_method_ii = create(:shipping_method, distributors: [distributor_i])
        shipping_method_iii = create(:shipping_method, distributors: [distributor_ii])
        shipping_method_iv = create(:shipping_method, distributors: [distributor_ii])
        order_cycle = create(:distributor_order_cycle,
                             distributors: [distributor_i, distributor_ii])
        order_cycle.preferred_shipping_methods << [shipping_method_i, shipping_method_iii]
        order = build(:order, distributor: distributor_i, order_cycle: order_cycle)

        available_shipping_methods = OrderAvailableShippingMethods.new(order).to_a

        expect(available_shipping_methods).to eq [shipping_method_i]
      end
    end
  end

  context "when FilterShippingMethods tag rules are in effect" do
    let(:user) { create(:user) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:other_distributor) { create(:distributor_enterprise) }
    let!(:distributor_shipping_method) { create(:shipping_method, distributors: [distributor]) }
    let!(:other_distributor_shipping_method) do
      create(:shipping_method, distributors: [other_distributor])
    end
    let(:customer) { create(:customer, user: user, enterprise: distributor) }
    let!(:tag_rule) {
      create(:filter_shipping_methods_tag_rule,
             enterprise: distributor,
             preferred_customer_tags: "local",
             preferred_shipping_method_tags: "local-delivery")
    }
    let!(:default_tag_rule) {
      create(:filter_shipping_methods_tag_rule,
             enterprise: distributor,
             is_default: true,
             preferred_shipping_method_tags: "local-delivery")
    }
    let!(:tagged_sm) { distributor_shipping_method }
    let!(:untagged_sm) { other_distributor_shipping_method }

    before do
      tagged_sm.update_attribute(:tag_list, 'local-delivery')
      distributor.shipping_methods = [tagged_sm, untagged_sm]
    end

    context "with a preferred visiblity of 'visible', default visibility of 'hidden'" do
      before {
        tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, 'visible')
      }
      before {
        default_tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility,
                                          'hidden')
      }

      let(:order_cycle) { create(:sells_own_order_cycle) }
      let(:order) { build(:order, distributor: distributor, order_cycle: order_cycle) }

      context "when the customer is nil" do
        let(:available_shipping_methods) { OrderAvailableShippingMethods.new(order).to_a }

        it "applies default action (hide)" do
          expect(available_shipping_methods).to include untagged_sm
          expect(available_shipping_methods).to_not include tagged_sm
        end
      end

      context "when a customer is present" do
        let(:available_shipping_methods) { OrderAvailableShippingMethods.new(order, customer).to_a }

        context "and the customer's tags match" do
          before do
            customer.update_attribute(:tag_list, 'local')
          end

          it "applies the action (show)" do
            expect(available_shipping_methods).to include tagged_sm, untagged_sm
          end
        end

        context "and the customer's tags don't match" do
          before do
            customer.update_attribute(:tag_list, 'something')
          end

          it "applies the default action (hide)" do
            expect(available_shipping_methods).to include untagged_sm
            expect(available_shipping_methods).to_not include tagged_sm
          end
        end
      end
    end

    context "with a preferred visiblity of 'hidden', default visibility of 'visible'" do
      before {
        tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility, 'hidden')
      }
      before {
        default_tag_rule.update_attribute(:preferred_matched_shipping_methods_visibility,
                                          'visible')
      }

      let(:order_cycle) { create(:sells_own_order_cycle) }
      let(:order) { build(:order, distributor: distributor, order_cycle: order_cycle) }

      context "when the customer is nil" do
        let(:available_shipping_methods) { OrderAvailableShippingMethods.new(order).to_a }

        it "applies default action (show)" do
          expect(available_shipping_methods).to include tagged_sm, untagged_sm
        end
      end

      context "when a customer is present" do
        let(:available_shipping_methods) { OrderAvailableShippingMethods.new(order, customer).to_a }

        context "and the customer's tags match" do
          before do
            customer.update_attribute(:tag_list, 'local')
          end

          it "applies the action (hide)" do
            expect(available_shipping_methods).to include untagged_sm
            expect(available_shipping_methods).to_not include tagged_sm
          end
        end

        context "and the customer's tags don't match" do
          before do
            customer.update_attribute(:tag_list, 'something')
          end

          it "applies the default action (show)" do
            expect(available_shipping_methods).to include tagged_sm, untagged_sm
          end
        end
      end
    end
  end
end
