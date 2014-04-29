require 'spec_helper'

feature "As a consumer I want to shop with a distributor", js: true do
  include AuthenticationWorkflow
  include WebHelper
  include UIComponentHelper

  describe "Viewing a distributor" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise)) }

    before do 
      order_cycle
      create_enterprise_group_for distributor
      visit "/"
      open_active_table_row
      click_link "Shop at #{distributor.name}"
    end

    it "shows a distributor with images" do
      visit shop_path
      page.should have_text distributor.name

      find("#tab_about a").click
      first("distributor img")['src'].should == distributor.logo.url(:thumb) 
      first("#about img")['src'].should == distributor.promo_image.url(:large) 
    end

    describe "with products in order cycles" do
      let(:product) { create(:product, supplier: supplier) }

      before do
        exchange = Exchange.find(order_cycle.exchanges.to_enterprises(distributor).outgoing.first.id) 
        exchange.variants << product.master
      end

      it "shows the suppliers/producers for a distributor" do
        visit shop_path
        find("#tab_producers a").click
        page.should have_content supplier.name 
      end
    end

    describe "selecting an order cycle" do
      let(:oc1) {create(:simple_order_cycle, distributors: [distributor], orders_close_at: 2.days.from_now)} 
      let(:oc2) {create(:simple_order_cycle, distributors: [distributor], orders_close_at: 3.days.from_now)} 
      let(:exchange1) { Exchange.find(oc1.exchanges.to_enterprises(distributor).outgoing.first.id) }
      let(:exchange2) { Exchange.find(oc2.exchanges.to_enterprises(distributor).outgoing.first.id) }
      it "selects an order cycle if only one is open" do
        # create order cycle
        exchange1.update_attribute :pickup_time, "turtles" 
        visit shop_path
        page.should have_selector "option[selected]", text: 'turtles'
      end

      describe "with multiple order cycles" do
        before do
          exchange1.update_attribute :pickup_time, "frogs" 
          exchange2.update_attribute :pickup_time, "turtles" 
          visit shop_path
        end

        it "shows a select with all order cycles, but doesn't show the products by default" do
          page.should have_selector "option", text: 'frogs'
          page.should have_selector "option", text: 'turtles'
          page.should_not have_selector("input.button.right", visible: true)
        end

        pending "shows the table after an order cycle is selected" do
          select "frogs", :from => "order_cycle_id"
          page.should have_selector("input.button.right", visible: true)
        end
        
        describe "with products in our order cycle" do
          let(:product) { create(:simple_product) }
          before do
            exchange1.variants << product.master
            visit shop_path
          end
          
          it "allows us to select an order cycle, thus showing products" do
            page.should_not have_content product.name 
            Spree::Order.last.order_cycle.should == nil

            select "frogs", :from => "order_cycle_id"
            page.should have_selector "products"
            page.should have_content "Orders close 2 days from now" 
            Spree::Order.last.order_cycle.should == oc1
            page.should have_content product.name 
          end
        end
      end

      describe "after selecting an order cycle with products visible" do
        let(:oc) { create(:simple_order_cycle, distributors: [distributor]) }
        let(:product) { create(:simple_product, price: 10) }
        let(:variant1) { create(:variant, product: product, price: 20) }
        let(:variant2) { create(:variant, product: product, price: 30) }
        let(:exchange) { Exchange.find(oc.exchanges.to_enterprises(distributor).outgoing.first.id) } 

        before do
          exchange.update_attribute :pickup_time, "frogs" 
          exchange.variants << product.master
          exchange.variants << variant1
          exchange.variants << variant2
          visit shop_path
          select "frogs", :from => "order_cycle_id"
          exchange
        end

        it "should not show quantity field for product with variants" do
          page.should_not have_selector("#variants_#{product.master.id}", visible: true)
        end

        it "expands variants by default" do
          page.should have_text variant1.options_text
        end

        it "expands variants" do
          find(".collapse").trigger "click"
          page.should_not have_text variant1.options_text
        end

        it "uses the adjusted price" do
          enterprise_fee1 = create(:enterprise_fee, amount: 20)
          enterprise_fee2 = create(:enterprise_fee, amount:  3)
          exchange.enterprise_fees = [enterprise_fee1, enterprise_fee2]
          exchange.save

          visit shop_path
          select "frogs", :from => "order_cycle_id"

          # All prices are as above plus $23 in fees

          # Page should not have product.price (with or without fee)
          page.should_not have_selector 'tr.product > td', text: "from $10.00"
          page.should_not have_selector 'tr.product > td', text: "from $33.00"

          # Page should have variant prices (with fee)
          page.should have_selector 'tr.variant > td.price', text: "$43.00"
          page.should have_selector 'tr.variant > td.price', text: "$53.00"

          # Product price should be listed as the lesser of these
          page.should have_selector 'tr.product > td', text: "from $43.00"
        end
      end

      describe "filtering products" do
        let(:oc) { create(:simple_order_cycle, distributors: [distributor]) }
        let(:p1) { create(:simple_product, on_demand: false) }
        let(:p2) { create(:simple_product, on_demand: true) }
        let(:p3) { create(:simple_product, on_demand: false) }
        let(:p4) { create(:simple_product, on_demand: false) }
        let(:p5) { create(:simple_product, on_demand: false) }
        let(:p6) { create(:simple_product, on_demand: false) }
        let(:p7) { create(:simple_product, on_demand: false) }
        let(:v1) { create(:variant, product: p4, unit_value: 2) }
        let(:v2) { create(:variant, product: p4, unit_value: 3, on_demand: false) }
        let(:v3) { create(:variant, product: p4, unit_value: 4, on_demand: true) }
        let(:v4) { create(:variant, product: p5) }
        let(:v5) { create(:variant, product: p5) }
        let(:v6) { create(:variant, product: p7) }

        before do
          p1.master.count_on_hand = 1
          p2.master.count_on_hand = 0
          p1.master.update_attribute(:count_on_hand, 1)
          p2.master.update_attribute(:count_on_hand, 0)
          p3.master.update_attribute(:count_on_hand, 0)
          p6.master.update_attribute(:count_on_hand, 1)
          p6.delete
          p7.master.update_attribute(:count_on_hand, 1)
          v1.update_attribute(:count_on_hand, 1)
          v2.update_attribute(:count_on_hand, 0)
          v3.update_attribute(:count_on_hand, 0)
          v4.update_attribute(:count_on_hand, 1)
          v5.update_attribute(:count_on_hand, 0)
          v6.update_attribute(:count_on_hand, 1)
          v6.update_attribute(:deleted_at, Time.now)
          exchange = Exchange.find(oc.exchanges.to_enterprises(distributor).outgoing.first.id) 
          exchange.update_attribute :pickup_time, "frogs" 
          exchange.variants << p1.master
          exchange.variants << p2.master
          exchange.variants << p3.master
          exchange.variants << p6.master
          exchange.variants << v1
          exchange.variants << v2
          exchange.variants << v3
          # v4 is in stock but not in distribution
          # v5 is out of stock and in the distribution
          # Neither should display, nor should their product, p5
          exchange.variants << v5
          exchange.variants << v6
          visit shop_path
          select "frogs", :from => "order_cycle_id"
          exchange
        end

        it "filters products based on availability" do
          # It shows on hand products
          page.should have_content p1.name
          page.should have_content p4.name

          # It shows on demand products
          page.should have_content p2.name

          # It does not show products that are neither on hand or on demand
          page.should_not have_content p3.name

          # It shows on demand variants
          page.should have_content v3.options_text

          # It does not show variants that are neither on hand or on demand
          page.should_not have_content v2.options_text

          # It does not show products that have no available variants in this distribution
          page.should_not have_content p5.name

          # It does not show deleted products
          page.should_not have_content p6.name

          # It does not show deleted variants
          page.should_not have_content v6.name
          page.should_not have_content p7.name
        end
      end

      describe "group buy products" do
        let(:oc) { create(:simple_order_cycle, distributors: [distributor]) }
        let(:product) { create(:simple_product, group_buy: true, on_hand: 15) }
        let(:product2) { create(:simple_product, group_buy: false) }

        describe "without variants" do
          before do
            build_and_select_order_cycle
          end

          it "should show group buy input" do
            page.should have_field "variant_attributes[#{product.master.id}][max_quantity]", :visible => true
            page.should_not have_field "variant_attributes[#{product2.master.id}][max_quantity]", :visible => true
          end
          
          it "should save group buy data to ze cart" do
            fill_in "variants[#{product.master.id}]", with: 5
            fill_in "variant_attributes[#{product.master.id}][max_quantity]", with: 9
            first("form.custom > input.button.right").click 
            page.should have_content product.name
            li = Spree::Order.order(:created_at).last.line_items.order(:created_at).last
            li.max_quantity.should == 9
            li.quantity.should == 5
          end

          scenario "adding a product with a max quantity less than quantity results in max_quantity==quantity" do
            fill_in "variants[#{product.master.id}]", with: 5
            fill_in "variant_attributes[#{product.master.id}][max_quantity]", with: 1
            first("form.custom > input.button.right").click 
            page.should have_content product.name
            li = Spree::Order.order(:created_at).last.line_items.order(:created_at).last
            li.max_quantity.should == 5
            li.quantity.should == 5
          end
        end

        describe "with variants on the product" do
          let(:variant) { create(:variant, product: product, on_hand: 10 ) }
          before do
            build_and_select_order_cycle_with_variants
          end

          it "should show group buy input" do
            page.should have_field "variant_attributes[#{variant.id}][max_quantity]", :visible => true
          end
          
          it "should save group buy data to ze cart" do
            fill_in "variants[#{variant.id}]", with: 6
            fill_in "variant_attributes[#{variant.id}][max_quantity]", with: 7
            first("form.custom > input.button.right").click 
            page.should have_content product.name
            li = Spree::Order.order(:created_at).last.line_items.order(:created_at).last
            li.max_quantity.should == 7
            li.quantity.should == 6
          end
        end
      end

      describe "adding products to cart" do
        let(:oc) { create(:simple_order_cycle, distributors: [distributor]) }
        let(:product) { create(:simple_product) }
        let(:variant) { create(:variant, product: product) }
        before do
          build_and_select_order_cycle_with_variants
        end
        it "should let us add products to our cart" do
          fill_in "variants[#{variant.id}]", with: "1"
          first("form.custom > input.button.right").click
          current_path.should == "/cart" 
          page.should have_content product.name
        end
      end

      context "when no order cycles are available" do
        it "tells us orders are closed" do
          visit shop_path
          page.should have_content "Orders are currently closed for this hub"
        end
        it "shows the last order cycle" do
          oc1 = create(:simple_order_cycle, distributors: [distributor], orders_close_at: 10.days.ago)
          visit shop_path
          page.should have_content "The last cycle closed 10 days ago"
        end
        it "shows the next order cycle" do
          oc1 = create(:simple_order_cycle, distributors: [distributor], orders_open_at: 10.days.from_now)
          visit shop_path
          page.should have_content "The next cycle opens in 10 days"
        end

        it "shows nothing when there is no future order cycle"
      end
    end
  end
end

def build_and_select_order_cycle
  exchange = Exchange.find(oc.exchanges.to_enterprises(distributor).outgoing.first.id) 
  exchange.update_attribute :pickup_time, "frogs" 
  exchange.variants << product.master
  visit shop_path
  select "frogs", :from => "order_cycle_id"
  exchange
end


def build_and_select_order_cycle_with_variants
  exchange = Exchange.find(oc.exchanges.to_enterprises(distributor).outgoing.first.id) 
  exchange.update_attribute :pickup_time, "frogs" 
  exchange.variants << product.master
  exchange.variants << variant 
  visit shop_path
  select "frogs", :from => "order_cycle_id"
  exchange
end
