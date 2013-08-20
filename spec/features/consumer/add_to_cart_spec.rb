require 'spec_helper'

feature %q{
    As a consumer
    I want to choose a distributor when adding products to my cart
    So that I can avoid making an order from many different distributors
} do
  include AuthenticationWorkflow
  include WebHelper

  context "with product distribution" do
    scenario "adding a product to the cart with no distributor chosen" do
      # Given a product and some distributors
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      p = create(:product, :distributors => [d1])
      create(:product, :distributors => [d2])

      # When I add an item to my cart without choosing a distributor
      visit spree.product_path p
      click_button 'Add To Cart'

      # Then I should see an error message
      page.should have_content "Please choose a distributor for this order."

      # And the product should not have been added to my cart
      Spree::Order.last.line_items.should be_empty
    end

    scenario "adding the first product to the cart", :future => true do
      # Given a product, some distributors and a defined shipping cost
      d1 = create(:distributor_enterprise, :name => "Green Grass")
      d2 = create(:distributor_enterprise, :name => "AusFarmers United")
      create(:product, :distributors => [d2])
      p = create(:product, :price => 12.34)
      create(:product_distribution, :product => p, :distributor => d1)

      # ... with a flat rate distribution fee of $1.23
      ef = p.product_distributions.first.enterprise_fee
      ef.calculator = Spree::Calculator::FlatRate.new preferred_amount: 1.23
      ef.calculator.save!

      # When I choose a distributor
      visit spree.root_path
      click_on "AusFarmers United"

      # And I add an item to my cart from a different distributor
      visit spree.product_path p
      select(d1.name, :from => 'distributor_id')
      click_button 'Add To Cart'

      # Then the correct totals should be displayed
      page.should have_selector 'span.item-total', :text => '$12.34'
      page.should have_selector 'span.distribution-total', :text => '$1.23'
      page.should have_selector 'span.grand-total', :text => '$13.57'

      # And the item should be in my cart
      order = Spree::Order.last
      line_item = order.line_items.first
      line_item.product.should == p

      # And my order should have its distributor set to the chosen distributor
      order.distributor.should == d1
    end

    context "adding a subsequent product to the cart" do
      it "when there are several valid distributors, allows a choice from these options" do
        # Given two products, both distributed by two distributors
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product, :distributors => [d1, d2])
        p2 = create(:product, :distributors => [d1, d2])

        # When I add the first to my cart via d1
        visit spree.product_path p1
        select d1.name, :from => 'distributor_id'
        click_button 'Add To Cart'

        # And I go to add the second, I should have a choice of distributor
        visit spree.product_path p2
        page.should have_selector '#distributor_id option', :text => d1.name
        page.should have_selector '#distributor_id option', :text => d2.name

        # When I add the second, both should be in my cart, and my distributor should be the one chosen second
        select d2.name, :from => 'distributor_id'
        click_button 'Add To Cart'
        visit spree.cart_path
        page.should have_selector 'h4 a', :text => p1.name
        page.should have_selector 'h4 a', :text => p2.name
        page.should have_selector "#current-distribution a", :text => d2.name
      end

      it "when the only valid distributor is the chosen one, does not allow the user to choose a distributor" do
        # Given two products, each at the same distributor
        d = create(:distributor_enterprise)
        p1 = create(:product, :distributors => [d])
        p2 = create(:product, :distributors => [d])

        # When I add the first to my cart
        visit spree.product_path p1
        select d.name, :from => 'distributor_id'
        click_button 'Add To Cart'

        # And I go to add the second, I should not have a choice of distributor
        visit spree.product_path p2
        page.should_not have_selector 'select#distributor_id'
        page.should     have_selector '.distributor-fixed', :text => "Your distributor for this order is #{d.name}"

        # When I add the second, both should be in my cart
        click_button 'Add To Cart'
        visit spree.cart_path
        page.should have_selector 'h4 a', :text => p1.name
        page.should have_selector 'h4 a', :text => p2.name
      end

      it "when the only valid distributor differs from the chosen one, alerts the user and changes distributor on add to cart" do
        # Given two products, one available at only one distributor
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product, :distributors => [d1, d2])
        p2 = create(:product, :distributors => [d2])

        # When I add the first to my cart
        visit spree.product_path p1
        select d1.name, from: 'distributor_id'
        click_button 'Add To Cart'

        # And I go to add the second
        visit spree.product_path p2

        # Then I should see a message offering to change distributor for my order
        page.should have_content "Your distributor for this order will be changed to #{d2.name} if you add this product to your cart."

        # When I add the second to my cart
        click_button 'Add To Cart'

        # Then My distributor should have changed
        page.should have_selector "#current-distribution a", :text => d2.name
      end

      it "does not allow the user to add a product from a distributor that cannot supply the cart's products" do
        # Given two products, each at a different distributor
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product, :distributors => [d1])
        p2 = create(:product, :distributors => [d2])

        # When I add one of them to my cart
        visit spree.product_path p1
        select d1.name, :from => 'distributor_id'
        click_button 'Add To Cart'

        # And I attempt to add the other
        visit spree.product_path p2

        # Then I should not be allowed to add the product
        page.should_not have_selector "button#add-to-cart-button"
        page.should have_content "Please complete your order at #{d1.name} before shopping with another distributor."
      end
    end

    describe 'with order cycles disabled' do
      before(:each) do
        OrderCyclesHelper.class_eval do
          def order_cycles_enabled?
            false
          end
        end
      end

      scenario "should not show order cycle details when adding to cart" do
        # Given a product and a distributor
        d = create(:distributor_enterprise)
        p = create(:product, :price => 12.34)

        # When I add an item to my cart
        visit spree.product_path p

        page.should_not have_selector '#order_cycle_id option'
      end

    end
  end

  context "with order cycle distribution" do
    before(:each) do
      OrderCyclesHelper.class_eval do
        def order_cycles_enabled?
          true
        end
      end
    end

    scenario "adding a product to the cart with no distribution chosen" do
      # Given a product and some distributors
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      p1 = create(:product)
      p2 = create(:product)
      create(:simple_order_cycle, :distributors => [d1], :variants => [p1.master])
      create(:simple_order_cycle, :distributors => [d2], :variants => [p2.master])

      # When I add an item to my cart without choosing a distributor or order cycle
      visit spree.product_path p1
      click_button 'Add To Cart'

      # Then I should see an error message
      page.should have_content "Please choose a distributor and order cycle for this order."

      # And the product should not have been added to my cart
      Spree::Order.last.line_items.should be_empty
    end

    scenario "adding the first product to the cart" do
      # Given a product and a distributor
      d = create(:distributor_enterprise)
      p = create(:product, :price => 12.34)
      oc = create(:simple_order_cycle, :distributors => [d], :variants => [p.master])

      # When I add an item to my cart
      visit spree.product_path p
      select d.name, :from => 'distributor_id'
      select oc.name, :from => 'order_cycle_id'
      click_button 'Add To Cart'

      # Then the correct totals should be displayed
      page.should have_selector 'span.item-total', :text => '$12.34'

      # TODO: Test these when order cycle fees is implemented
      # page.should have_selector 'span.distribution-total', :text => '$1.23'
      # page.should have_selector 'span.grand-total', :text => '$13.57'

      # And the item should be in my cart
      order = Spree::Order.last
      line_item = order.line_items.first
      line_item.product.should == p

      # And my order should have its distributor and order cycle set to the chosen ones
      order.distributor.should == d
      order.order_cycle.should == oc
    end

    scenario "adding a product to the cart with an invalid distribution combination" do
      # Given a product and some distributors
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      p = create(:product, :price => 12.34)
      oc1 = create(:simple_order_cycle, :distributors => [d1], :variants => [p.master])
      oc2 = create(:simple_order_cycle, :distributors => [d2], :variants => [p.master])

      # When I attempt to add the product to my cart with an invalid distribution
      visit spree.product_path p
      select d1.name, :from => 'distributor_id'
      select oc2.name, :from => 'order_cycle_id'
      click_button 'Add To Cart'

      # Then I should see an error message
      page.should have_content "That product is not available from the chosen distributor or order cycle."

      # And the product should not be in my cart
      Spree::Order.last.line_items.should be_empty
    end


    context "adding a subsequent product to the cart" do
      it "when there are several valid order cycles, allows a choice from these options" do
        # Given two products, both distributed by two distributors
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:simple_order_cycle,
                     :distributors => [d1, d2], :variants => [p1.master, p2.master])
        oc2 = create(:simple_order_cycle,
                     :distributors => [d1, d2], :variants => [p1.master, p2.master])

        # When I add the first to my cart via d1/oc1
        visit spree.product_path p1
        select d1.name, :from => 'distributor_id'
        select oc1.name, :from => 'order_cycle_id'
        click_button 'Add To Cart'

        # And I go to add the second, I should have a choice of order cycle and distributor
        visit spree.product_path p2
        page.should have_selector '#distributor_id option', :text => d1.name
        page.should have_selector '#distributor_id option', :text => d2.name
        page.should have_selector '#order_cycle_id option', :text => oc1.name
        page.should have_selector '#order_cycle_id option', :text => oc2.name

        # When I add the second, both should be in my cart, and my
        # distributor and order cycle should be the one chosen second
        select d2.name, :from => 'distributor_id'
        select oc2.name, :from => 'order_cycle_id'
        click_button 'Add To Cart'
        visit spree.cart_path
        page.should have_selector 'h4 a', :text => p1.name
        page.should have_selector 'h4 a', :text => p2.name
        page.should have_selector "#current-distribution a", :text => d2.name
        page.should have_selector "#current-distribution a", :text => oc2.name
      end

      it "when the only valid order cycle is the chosen one, does not allow the user to choose an order cycle" do
        # Given two products, each at the same distributor
        d = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc = create(:simple_order_cycle, :distributors => [d],
                    :variants => [p1.master, p2.master])

        # When I add the first to my cart
        visit spree.product_path p1
        select d.name, :from => 'distributor_id'
        select oc.name, :from => 'order_cycle_id'
        click_button 'Add To Cart'

        # And I go to add the second, I should not have a choice of distributor or order cycle
        visit spree.product_path p2
        page.should_not have_selector 'select#distributor_id'
        page.should     have_selector '.distributor-fixed', :text => "Your distributor for this order is #{d.name}"
        page.should_not have_selector 'select#order_cycle_id'
        page.should     have_selector '.order-cycle-fixed', :text => "Your order cycle for this order is #{oc.name}"

        # When I add the second, both should be in my cart
        click_button 'Add To Cart'
        visit spree.cart_path
        page.should have_selector 'h4 a', :text => p1.name
        page.should have_selector 'h4 a', :text => p2.name
      end

      it "when the only valid distributor differs from the chosen one, alerts the user and changes distributor on add to cart" do
        # Given two products, one available at only one distributor
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:simple_order_cycle, :distributors => [d1], :variants => [p1.master])
        oc2 = create(:simple_order_cycle, :distributors => [d2], :variants => [p1.master, p2.master])

        # When I add the first to my cart
        visit spree.product_path p1
        select d1.name, from: 'distributor_id'
        select oc1.name, from: 'order_cycle_id'

        click_button 'Add To Cart'

        # And I go to add the second
        visit spree.product_path p2

        # Then I should see a message offering to change distributor for my order
        page.should have_content "Your distributor for this order will be changed to #{d2.name} if you add this product to your cart."

        # When I add the second to my cart
        click_button 'Add To Cart'

        # Then my distributor should have changed
        page.should have_selector "#current-distribution a", :text => d2.name
      end

      it "does not allow the user to add a product from an order cycle that cannot supply the cart's products" do
        # Given two products, each at a different order cycle
        d = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:simple_order_cycle, :distributors => [d], :variants => [p1.master])
        oc2 = create(:simple_order_cycle, :distributors => [d], :variants => [p2.master])

        # When I add one of them to my cart
        visit spree.product_path p1
        select d.name, :from => 'distributor_id'
        select oc1.name, :from => 'order_cycle_id'
        click_button 'Add To Cart'

        # And I attempt to add the other
        visit spree.product_path p2

        # Then I should not be allowed to add the product
        page.should_not have_selector "button#add-to-cart-button"
        page.should have_content "Please complete your order from #{oc1.name} before shopping in a different order cycle."
      end
    end
  end

  context "group buys" do
    scenario "adding a product to the cart for a group buy" do
      # Given a group buy product and a distributor
      d = create(:distributor_enterprise)
      p = create(:product, :distributors => [d], :group_buy => true)

      # When I add the item to my cart
      visit spree.product_path p
      select d.name, :from => 'distributor_id'
      fill_in "variants_#{p.master.id}", :with => 2
      fill_in "variant_attributes_#{p.master.id}_max_quantity", :with => 3
      click_button 'Add To Cart'

      # Then the item should be in my cart with correct quantities
      order = Spree::Order.last
      li = order.line_items.first
      li.product.should == p
      li.quantity.should == 2
      li.max_quantity.should == 3
    end

    scenario "adding a product with variants to the cart for a group buy" do
      # Given a group buy product with variants and a distributor
      d = create(:distributor_enterprise)
      p = create(:product, :distributors => [d], :group_buy => true)
      create(:variant, :product => p)

      # When I add the item to my cart
      visit spree.product_path p
      select d.name, :from => 'distributor_id'
      fill_in "quantity", :with => 2
      fill_in "max_quantity", :with => 3
      click_button 'Add To Cart'

      # Then the item should be in my cart with correct quantities
      order = Spree::Order.last
      li = order.line_items.first
      li.product.should == p
      li.quantity.should == 2
      li.max_quantity.should == 3
    end

    scenario "adding a product to cart that is not a group buy does not show max quantity field" do
      # Given a group buy product and a distributor
      d = create(:distributor_enterprise)
      p = create(:product, :distributors => [d], :group_buy => false)

      # When I view the add to cart form, there should not be a max quantity field
      visit spree.product_path p

      page.should_not have_selector "#variant_attributes_#{p.master.id}_max_quantity"
    end

    scenario "adding a product with a max quantity less than quantity results in max_quantity==quantity" do
      # Given a group buy product and a distributor
      d = create(:distributor_enterprise)
      p = create(:product, :distributors => [d], :group_buy => true)

      # When I add the item to my cart
      visit spree.product_path p
      select d.name, :from => 'distributor_id'
      fill_in "variants_#{p.master.id}", :with => 2
      fill_in "variant_attributes_#{p.master.id}_max_quantity", :with => 1
      click_button 'Add To Cart'

      # Then the item should be in my cart with correct quantities
      order = Spree::Order.last
      li = order.line_items.first
      li.product.should == p
      li.quantity.should == 2
      li.max_quantity.should == 2
    end
  end
end
