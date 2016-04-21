require 'spec_helper'

describe ShopController do
  let(:distributor) { create(:distributor_enterprise) }

  it "redirects to the home page if no distributor is selected" do
    spree_get :show
    response.should redirect_to root_path
  end

  describe "with a distributor in place" do
    before do
      controller.stub(:current_distributor).and_return distributor
    end

    describe "selecting an order cycle" do
      it "should select an order cycle when only one order cycle is open" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        spree_get :show
        controller.current_order_cycle.should == oc1
      end

      it "should not set an order cycle when multiple order cycles are open" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])
        spree_get :show
        controller.current_order_cycle.should be_nil
      end

      it "should allow the user to post to select the current order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])

        spree_post :order_cycle, order_cycle_id: oc2.id
        response.should be_success
        controller.current_order_cycle.should == oc2
      end

      context "JSON tests" do
        render_views

        it "should return the order cycle details when the OC is selected" do
          oc1 = create(:simple_order_cycle, distributors: [distributor])
          oc2 = create(:simple_order_cycle, distributors: [distributor])

          spree_post :order_cycle, order_cycle_id: oc2.id
          response.should be_success
          response.body.should have_content oc2.id
        end

        it "should return the current order cycle when hit with GET" do
          oc1 = create(:simple_order_cycle, distributors: [distributor])
          controller.stub(:current_order_cycle).and_return oc1
          spree_get :order_cycle
          response.body.should have_content oc1.id
        end
      end

      it "should not allow the user to select an invalid order cycle" do
        oc1 = create(:simple_order_cycle, distributors: [distributor])
        oc2 = create(:simple_order_cycle, distributors: [distributor])
        oc3 = create(:simple_order_cycle, distributors: [create(:distributor_enterprise)])

        spree_post :order_cycle, order_cycle_id: oc3.id
        response.status.should == 404
        controller.current_order_cycle.should be_nil
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
          controller.stub(:current_order_cycle).and_return order_cycle
          xhr :get, :products
          response.should be_success
        end

        it "does not return products if no order cycle is selected" do
          controller.stub(:current_order_cycle).and_return nil
          xhr :get, :products
          response.status.should == 404
          response.body.should be_empty
        end
      end
    end

    describe "determining rule relevance" do
      let(:products_json) { double(:products_json) }

      before do
        # allow(controller).to receive(:products_json) { products_json }
        allow(controller).to receive(:relevant_tag_rules) { relevant_tag_rules }
        allow(controller).to receive(:apply_tag_rules) { "some filtered json" }
      end

      context "when no relevant rules exist" do
        let(:relevant_tag_rules) { [] }

        before { allow(controller).to receive(:relevant_rules) { relevant_rules } }

        it "does not attempt to apply any rules" do
          controller.send(:filtered_json, products_json)
          expect(expect(controller).to_not have_received(:apply_tag_rules))
        end

        it "returns products as JSON" do
          expect(controller.send(:filtered_json, products_json)).to eq products_json
        end
      end

      context "when relevant rules exist" do
        let(:tag_rule) { create(:filter_products_tag_rule, preferred_customer_tags: "tag1", preferred_variant_tags: "tag1", preferred_matched_variants_visibility: "hidden" ) }
        let(:relevant_tag_rules) { [tag_rule] }

        it "attempts to apply any rules" do
          controller.send(:filtered_json, products_json)
          expect(controller).to have_received(:apply_tag_rules).with(relevant_tag_rules, products_json)
        end

        it "returns filtered JSON" do
          expect(controller.send(:filtered_json, products_json)).to eq "some filtered json"
        end
      end
    end

    describe "applying tag rules" do
      let(:product1) { { id: 1, name: 'product 1', "variants" => [{ id: 4, "tag_list" => ["tag1"] }] } }
      let(:product2) { { id: 2, name: 'product 2', "variants" => [{ id: 5, "tag_list" => ["tag1"] }, {id: 9, "tag_list" => ["tag2"]}] } }
      let(:product3) { { id: 3, name: 'product 3', "variants" => [{ id: 6, "tag_list" => ["tag3"] }] } }
      let!(:products_array) { [product1, product2, product3] }
      let!(:products_json) { JSON.unparse( products_array ) }
      let(:tag_rule) { create(:filter_products_tag_rule, preferred_customer_tags: "tag1", preferred_variant_tags: "tag1", preferred_matched_variants_visibility: "hidden" ) }
      let(:relevant_tag_rules) { [tag_rule] }

      before do
        allow(controller).to receive(:current_order) { order }
        allow(tag_rule).to receive(:set_context)
        allow(tag_rule).to receive(:apply)
        allow(distributor).to receive(:apply_tag_rules).and_call_original
      end

      context "when a current order with a customer does not exist" do
        let(:order) { double(:order, customer: nil) }

        it "sets the context customer_tags as an empty array" do
          controller.send(:apply_tag_rules, relevant_tag_rules, products_json)
          expect(distributor).to have_received(:apply_tag_rules).with(rules: relevant_tag_rules, subject: JSON.parse(products_json), :customer_tags=>[])
        end
      end

      context "when a customer does exist" do
        let(:order) { double(:order, customer: double(:customer, tag_list: ["tag1", "tag2"])) }

        it "sets the context customer_tags" do
          controller.send(:apply_tag_rules, relevant_tag_rules, products_json)
          expect(distributor).to have_received(:apply_tag_rules).with(rules: relevant_tag_rules, subject: JSON.parse(products_json), :customer_tags=>["tag1", "tag2"])
        end

        context "applies the rule" do
          before do
            allow(tag_rule).to receive(:set_context).and_call_original
            allow(tag_rule).to receive(:apply).and_call_original
          end

          it "applies the rule" do
            result = controller.send(:apply_tag_rules, relevant_tag_rules, products_json)
            expect(tag_rule).to have_received(:apply)
            expect(result).to eq JSON.unparse([{ id: 2, name: 'product 2', variants: [{id: 9, tag_list: ["tag2"]}] }, product3])
          end
        end
      end
    end
  end
end
