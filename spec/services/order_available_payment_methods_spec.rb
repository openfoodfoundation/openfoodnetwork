# frozen_string_literal: true

require 'spec_helper'

describe OrderAvailablePaymentMethods do
  context "when the order has no current_distributor" do
    it "returns an empty array" do
      order_cycle = create(:sells_own_order_cycle)
      order = build(:order, distributor: nil, order_cycle: order_cycle)

      expect(OrderAvailablePaymentMethods.new(order).to_a).to eq []
    end
  end

  it "does not return 'back office only' payment method" do
    distributor = create(:distributor_enterprise)
    frontend_payment_method = create(:payment_method, distributors: [distributor])
    backoffice_only_payment_method = create(:payment_method,
                                            distributors: [distributor],
                                            display_on: 'back_end')
    order_cycle = create(:sells_own_order_cycle)
    order = build(:order, distributor: distributor, order_cycle: order_cycle)

    available_payment_methods = OrderAvailablePaymentMethods.new(order).to_a

    expect(available_payment_methods).to eq [frontend_payment_method]
  end

  it "does not return payment methods which are not configured correctly" do
    distributor = create(:distributor_enterprise)
    frontend_payment_method = create(:payment_method, distributors: [distributor])
    unconfigured_payment_method = create(:stripe_sca_payment_method,
                                         distributors: [distributor],
                                         display_on: 'back_end')
    order_cycle = create(:sells_own_order_cycle)
    order = build(:order, distributor: distributor, order_cycle: order_cycle)

    available_payment_methods = OrderAvailablePaymentMethods.new(order).to_a

    expect(available_payment_methods).to eq [frontend_payment_method]
  end

  context "when no tag rules are in effect" do
    context "sells own order cycle i.e. simple" do
      it "only returns the payment methods which are available on the order cycle
          and belong to the order distributor" do
        distributor_i = create(:distributor_enterprise)
        distributor_ii = create(:distributor_enterprise)
        distributor_iii = create(:distributor_enterprise)
        payment_method_i = create(:payment_method, distributors: [distributor_i])
        payment_method_ii = create(:payment_method, distributors: [distributor_ii])
        payment_method_iii = create(:payment_method, distributors: [distributor_iii])
        order_cycle = create(:sells_own_order_cycle, distributors: [distributor_i, distributor_ii])
        order = build(:order, distributor: distributor_i, order_cycle: order_cycle)

        available_payment_methods = OrderAvailablePaymentMethods.new(order).to_a

        expect(available_payment_methods).to eq [payment_method_i]
      end
    end

    context "distributor order cycle i.e. not simple" do
      it "only returns the payment methods which are available on the order cycle
          and belong to the order distributor" do
        distributor_i = create(:distributor_enterprise, payment_methods: [])
        distributor_ii = create(:distributor_enterprise, payment_methods: [])
        payment_method_i = create(:payment_method, distributors: [distributor_i])
        payment_method_ii = create(:payment_method, distributors: [distributor_i])
        payment_method_iii = create(:payment_method, distributors: [distributor_ii])
        payment_method_iv = create(:payment_method, distributors: [distributor_ii])
        order_cycle = create(:distributor_order_cycle,
                             distributors: [distributor_i, distributor_ii])
        order_cycle.selected_distributor_payment_methods << [
          distributor_i.distributor_payment_methods.first,
          distributor_ii.distributor_payment_methods.first,
        ]
        order = build(:order, distributor: distributor_i, order_cycle: order_cycle)

        available_payment_methods = OrderAvailablePaymentMethods.new(order).to_a

        expect(available_payment_methods).to eq [payment_method_i]
      end
    end
  end

  context "when FilterPaymentMethods tag rules are in effect" do
    let(:user) { create(:user) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:other_distributor) { create(:distributor_enterprise) }
    let!(:distributor_payment_method) { create(:payment_method, distributors: [distributor]) }
    let!(:other_distributor_payment_method) do
      create(:payment_method, distributors: [other_distributor])
    end
    let(:customer) { create(:customer, user: user, enterprise: distributor) }
    let!(:tag_rule) {
      create(:filter_payment_methods_tag_rule,
             enterprise: distributor,
             preferred_customer_tags: "local",
             preferred_payment_method_tags: "local-delivery")
    }
    let!(:default_tag_rule) {
      create(:filter_payment_methods_tag_rule,
             enterprise: distributor,
             is_default: true,
             preferred_payment_method_tags: "local-delivery")
    }
    let!(:tagged_payment_method) { distributor_payment_method }
    let!(:untagged_payment_method) { other_distributor_payment_method }

    before do
      tagged_payment_method.update_attribute(:tag_list, 'local-delivery')
      distributor.payment_methods = [tagged_payment_method, untagged_payment_method]
    end

    context "with a preferred visiblity of 'visible', default visibility of 'hidden'" do
      before {
        tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, 'visible')
      }
      before {
        default_tag_rule.update_attribute(:preferred_matched_payment_methods_visibility,
                                          'hidden')
      }

      let(:order_cycle) { create(:sells_own_order_cycle) }
      let(:order) { build(:order, distributor: distributor, order_cycle: order_cycle) }

      context "when the customer is nil" do
        let(:available_payment_methods) { OrderAvailablePaymentMethods.new(order).to_a }

        it "applies default action (hide)" do
          expect(available_payment_methods).to include untagged_payment_method
          expect(available_payment_methods).to_not include tagged_payment_method
        end
      end

      context "when a customer is present" do
        let(:available_payment_methods) { OrderAvailablePaymentMethods.new(order, customer).to_a }

        context "and the customer's tags match" do
          before do
            customer.update_attribute(:tag_list, 'local')
          end

          it "applies the action (show)" do
            expect(available_payment_methods).to include(
              tagged_payment_method,
              untagged_payment_method
            )
          end
        end

        context "and the customer's tags don't match" do
          before do
            customer.update_attribute(:tag_list, 'something')
          end

          it "applies the default action (hide)" do
            expect(available_payment_methods).to include untagged_payment_method
            expect(available_payment_methods).to_not include tagged_payment_method
          end
        end
      end
    end

    context "with a preferred visiblity of 'hidden', default visibility of 'visible'" do
      before {
        tag_rule.update_attribute(:preferred_matched_payment_methods_visibility, 'hidden')
      }
      before {
        default_tag_rule.update_attribute(:preferred_matched_payment_methods_visibility,
                                          'visible')
      }

      let(:order_cycle) { create(:sells_own_order_cycle) }
      let(:order) { build(:order, distributor: distributor, order_cycle: order_cycle) }

      context "when the customer is nil" do
        let(:available_payment_methods) { OrderAvailablePaymentMethods.new(order).to_a }

        it "applies default action (show)" do
          expect(available_payment_methods).to include(
            tagged_payment_method,
            untagged_payment_method
          )
        end
      end

      context "when a customer is present" do
        let(:available_payment_methods) { OrderAvailablePaymentMethods.new(order, customer).to_a }

        context "and the customer's tags match" do
          before do
            customer.update_attribute(:tag_list, 'local')
          end

          it "applies the action (hide)" do
            expect(available_payment_methods).to include untagged_payment_method
            expect(available_payment_methods).to_not include tagged_payment_method
          end
        end

        context "and the customer's tags don't match" do
          before do
            customer.update_attribute(:tag_list, 'something')
          end

          it "applies the default action (show)" do
            expect(available_payment_methods).to include(
              tagged_payment_method,
              untagged_payment_method
            )
          end
        end
      end
    end
  end

  context "when two distributors implement the same payment methods" do
    context "only one distributor supports the two payment methods in the order cycle" do
      let(:oc){ create(:order_cycle) }
      let(:payment_method){ create(:payment_method) }
      let(:payment_method2){ create(:payment_method) }
      let(:d1){ oc.distributors.first }
      let(:d2){ oc.distributors.second }
      before {
        d1.payment_methods << payment_method
        d1.payment_methods << payment_method2
        d2.payment_methods << payment_method
        d2.payment_methods << payment_method2
        oc.selected_distributor_payment_methods << d1.distributor_payment_methods.first
        oc.selected_distributor_payment_methods << d1.distributor_payment_methods.second
        oc.selected_distributor_payment_methods << d2.distributor_payment_methods.first
      }
      it do
        order = build(:order, distributor: d2, order_cycle: oc)
        order_available_payment_methods = OrderAvailablePaymentMethods.new(order).to_a
        expect(order_available_payment_methods).to eq([d2.payment_methods.first])
      end
    end
  end
end
