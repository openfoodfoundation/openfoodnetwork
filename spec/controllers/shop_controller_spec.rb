require 'spec_helper'

describe ShopController, type: :controller do
  let!(:pm) { create(:payment_method) }
  let!(:sm) { create(:shipping_method) }
  let(:distributor) { create(:distributor_enterprise, payment_methods: [pm], shipping_methods: [sm]) }

  it "redirects to the home page if no distributor is selected" do
    spree_get :show
    expect(response).to redirect_to root_path
  end

  describe "with a distributor in place" do
    before do
      allow(controller).to receive(:current_distributor).and_return distributor
    end

    describe "selecting an order cycle" do
      it "should select an order cycle when only one order cycle is open" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        spree_get :show
        expect(controller.current_order_cycle).to eq(oc1)
      end

      it "should not set an order cycle when multiple order cycles are open" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])
        spree_get :show
        expect(controller.current_order_cycle).to be_nil
      end

      it "should allow the user to post to select the current order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])

        spree_post :order_cycle, order_cycle_id: oc2.id
        expect(response).to be_success
        expect(controller.current_order_cycle).to eq(oc2)
      end

      context "JSON tests" do
        render_views

        it "should return the order cycle details when the OC is selected" do
          oc1 = create(:simple_order_cycle, distributors: [distributor])
          oc2 = create(:simple_order_cycle, distributors: [distributor])

          spree_post :order_cycle, order_cycle_id: oc2.id
          expect(response).to be_success
          expect(response.body).to have_content oc2.id
        end

        it "should return the current order cycle when hit with GET" do
          oc1 = create(:simple_order_cycle, distributors: [distributor])
          allow(controller).to receive(:current_order_cycle).and_return oc1
          spree_get :order_cycle
          expect(response.body).to have_content oc1.id
        end

        context "when the order cycle has already been set" do
          let(:oc1) { create(:simple_order_cycle, distributors: [distributor]) }
          let(:oc2) { create(:simple_order_cycle, distributors: [distributor]) }
          let(:order) { create(:order, order_cycle: oc1) }

          before { allow(controller).to receive(:current_order) { order } }

          it "returns the new order cycle details" do
            spree_post :order_cycle, order_cycle_id: oc2.id
            expect(response).to be_success
            expect(response.body).to have_content oc2.id
          end
        end
      end

      it "should not allow the user to select an invalid order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])
        oc3 = create(:simple_order_cycle, distributors: [create(:distributor_enterprise)])

        spree_post :order_cycle, order_cycle_id: oc3.id
        expect(response.status).to eq(404)
        expect(controller.current_order_cycle).to be_nil
      end
    end


    describe "returning products" do
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
      let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }

      describe "requests and responses" do
        let(:product) { create(:product) }

        before do
          exchange.variants << product.variants.first
        end

        it "returns products via JSON" do
          allow(controller).to receive(:current_order_cycle).and_return order_cycle
          xhr :get, :products
          expect(response).to be_success
        end

        it "does not return products if no order cycle is selected" do
          allow(controller).to receive(:current_order_cycle).and_return nil
          xhr :get, :products
          expect(response.status).to eq(404)
          expect(response.body).to be_empty
        end
      end
    end

    describe "determining rule relevance" do
      let(:products_json) { double(:products_json) }
      let(:applicator) { double(:applicator) }

      before do
        allow(applicator).to receive(:rules) { tag_rules }
        allow(controller).to receive(:applicator) { applicator }
        allow(controller).to receive(:filter) { "some filtered json" }
      end

      context "when no relevant rules exist" do
        let(:tag_rules) { [] }

        it "does not attempt to apply any rules" do
          controller.send(:filtered_json, products_json)
          expect(expect(controller).to_not have_received(:filter))
        end

        it "returns products as JSON" do
          expect(controller.send(:filtered_json, products_json)).to eq products_json
        end
      end

      context "when relevant rules exist" do
        let(:tag_rule) { create(:filter_products_tag_rule, preferred_customer_tags: "tag1", preferred_variant_tags: "tag1", preferred_matched_variants_visibility: "hidden" ) }
        let(:tag_rules) { [tag_rule] }

        it "attempts to apply any rules" do
          controller.send(:filtered_json, products_json)
          expect(controller).to have_received(:filter).with(products_json)
        end

        it "returns filtered JSON" do
          expect(controller.send(:filtered_json, products_json)).to eq "some filtered json"
        end
      end
    end

    describe "loading available order cycles" do
      let(:user) { create(:user) }
      before { allow(controller).to receive(:spree_current_user) { user } }

      context "when FilterProducts tag rules are in effect" do
        let(:customer) { create(:customer, user: user, enterprise: distributor) }
        let!(:tag_rule) { create(:filter_products_tag_rule,
          enterprise: distributor,
          preferred_customer_tags: "member",
          preferred_variant_tags: "members-only")
        }
        let!(:default_tag_rule) { create(:filter_products_tag_rule,
          enterprise: distributor,
          is_default: true,
          preferred_variant_tags: "members-only")
        }
        let(:product1) { { "id" => 1, "name" => 'product 1', "variants" => [{ "id" => 4, "tag_list" => ["members-only"] }] } }
        let(:product2) { { "id" => 2, "name" => 'product 2', "variants" => [{ "id" => 5, "tag_list" => ["members-only"] }, {"id" => 9, "tag_list" => ["something"]}] } }
        let(:product3) { { "id" => 3, "name" => 'product 3', "variants" => [{ "id" => 6, "tag_list" => ["something-else"] }] } }
        let(:product2_without_v5) { { "id" => 2, "name" => 'product 2', "variants" => [{"id" => 9, "tag_list" => ["something"]}] } }
        let!(:products_array) { [product1, product2, product3] }
        let!(:products_json) { JSON.unparse( products_array ) }

        before do
          allow(controller).to receive(:current_order) { order }
        end

        context "with a preferred visiblity of 'visible', default visibility of 'hidden'" do
          before { tag_rule.update_attribute(:preferred_matched_variants_visibility, 'visible') }
          before { default_tag_rule.update_attribute(:preferred_matched_variants_visibility, 'hidden') }

          let(:filtered_products) { JSON.parse(controller.send(:filter, products_json)) }

          context "when the customer is nil" do
            it "applies default action (hide)" do
              expect(controller.current_customer).to be nil
              expect(filtered_products).to include product2_without_v5, product3
              expect(filtered_products).to_not include product1, product2
            end
          end

          context "when the customer's tags match" do
            before { customer.update_attribute(:tag_list, 'member') }

            it "applies the action (show)" do
              expect(controller.current_customer).to eq customer
              expect(filtered_products).to include product1, product2, product3
            end
          end

          context "when the customer's tags don't match" do
            before { customer.update_attribute(:tag_list, 'something') }

            it "applies the default action (hide)" do
              expect(controller.current_customer).to eq customer
              expect(filtered_products).to include product2_without_v5, product3
              expect(filtered_products).to_not include product1, product2
            end
          end
        end

        context "with a preferred visiblity of 'hidden', default visibility of 'visible'" do
          before { tag_rule.update_attribute(:preferred_matched_variants_visibility, 'hidden') }
          before { default_tag_rule.update_attribute(:preferred_matched_variants_visibility, 'visible') }

          let(:filtered_products) { JSON.parse(controller.send(:filter, products_json)) }

          context "when the customer is nil" do
            it "applies default action (show)" do
              expect(controller.current_customer).to be nil
              expect(filtered_products).to include product1, product2, product3
            end
          end

          context "when the customer's tags match" do
            before { customer.update_attribute(:tag_list, 'member') }

            it "applies the action (hide)" do
              expect(controller.current_customer).to eq customer
              expect(filtered_products).to include product2_without_v5, product3
              expect(filtered_products).to_not include product1, product2
            end
          end

          context "when the customer's tags don't match" do
            before { customer.update_attribute(:tag_list, 'something') }

            it "applies the default action (show)" do
              expect(controller.current_customer).to eq customer
              expect(filtered_products).to include product1, product2, product3
            end
          end
        end
      end
    end
  end
end
