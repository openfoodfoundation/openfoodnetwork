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
    context "order cycle selling own produce only i.e. shipping methods cannot be customised" do
      it "returns all shipping methods belonging to the enterprise" do
        order_cycle = create(:sells_own_order_cycle)
        enterprise = order_cycle.coordinator
        shipping_method = create(:shipping_method, distributors: [enterprise])
        other_enterprise = create(:enterprise)
        other_enterprise_shipping_method = create(:shipping_method,
                                                  distributors: [other_enterprise])
        order = build(:order, distributor: enterprise, order_cycle: order_cycle)

        available_shipping_methods = OrderAvailableShippingMethods.new(order).to_a

        expect(order_cycle.shipping_methods).to be_empty
        expect(available_shipping_methods).to eq [shipping_method]
      end
    end

    context "distributor order cycle" do
      it "only returns shipping methods which belong to the order distributor
          and have been added to the order cycle" do
        distributor = create(:distributor_enterprise)
        shipping_method_i = create(:shipping_method, distributors: [distributor])
        shipping_method_ii = create(:shipping_method, distributors: [distributor])
        order_cycle = create(:simple_order_cycle,
                             distributors: [distributor], shipping_methods: [shipping_method_i])
        order = build(:order, distributor: distributor, order_cycle: order_cycle)

        available_shipping_methods = OrderAvailableShippingMethods.new(order).to_a

        expect(available_shipping_methods).to eq order_cycle.shipping_methods
        expect(available_shipping_methods).to eq [shipping_method_i]
      end

      it "doesn't return shipping methods which have been added to the order cycle
          when they don't belong to the order distributor" do
        distributor_i = create(:distributor_enterprise)
        distributor_ii = create(:distributor_enterprise)
        shipping_method_i = create(:shipping_method, distributors: [distributor_i])
        shipping_method_ii = create(:shipping_method, distributors: [distributor_ii])
        order_cycle = create(:simple_order_cycle,
                             distributors: [distributor_i, distributor_ii],
                             shipping_methods: [shipping_method_i, shipping_method_ii])
        order = build(:order, distributor: distributor_ii, order_cycle: order_cycle)

        available_shipping_methods = OrderAvailableShippingMethods.new(order).to_a

        expect(available_shipping_methods).not_to eq order_cycle.shipping_methods
        expect(available_shipping_methods).to eq [shipping_method_ii]
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

      context "order cycle selling own produce only" do
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

      context "distributor order cycle" do
        context "when the shipping method without the tag rule is attached to the order cycle
                 and the shipping method with the tag rule is not" do
          let(:order_cycle) do
            create(:distributor_order_cycle,
                   distributors: [distributor], shipping_methods: [untagged_sm])
          end
          let(:order) { build(:order, distributor: distributor, order_cycle: order_cycle) }
          let(:available_shipping_methods) { OrderAvailableShippingMethods.new(order, customer).to_a }

          context "when the customer's tags match" do
            before do
              customer.update_attribute(:tag_list, 'local')
            end

            it "doesn't display the shipping method with the prefered visibility 'visible' tag
                even though the customer's tags match
                because it hasn't been attached to the order cycle" do
              expect(available_shipping_methods).to include untagged_sm
              expect(available_shipping_methods).to_not include tagged_sm
            end
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

      context "order cycle selling own produce only" do
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

      context "distributor order cycle" do
        context "when the shipping method without the tag rule is attached to the order cycle
                 and the shipping method with the tag rule is not" do
          let(:order_cycle) do
            create(:distributor_order_cycle,
                   distributors: [distributor], shipping_methods: [untagged_sm])
          end
          let(:order) { build(:order, distributor: distributor, order_cycle: order_cycle) }

          context "when the customer is nil" do
            let(:available_shipping_methods) { OrderAvailableShippingMethods.new(order).to_a }

            it "doesn't display the shipping method tagged to be visible by default
                because it is not attached to the order cycle" do
              expect(available_shipping_methods).to include untagged_sm
              expect(available_shipping_methods).to_not include tagged_sm
            end
          end

          context "when a customer is present" do
            let(:available_shipping_methods) { OrderAvailableShippingMethods.new(order, customer).to_a }

            context "when the customer's tags don't match" do
              before do
                customer.update_attribute(:tag_list, 'something')
              end

              it "doesn't display the shipping method tagged to be visible by default
                  because it is not attached to the order cycle" do
                expect(available_shipping_methods).to include untagged_sm
                expect(available_shipping_methods).to_not include tagged_sm
              end
            end
          end
        end
      end
    end
  end
end
