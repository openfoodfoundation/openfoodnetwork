require 'spec_helper'

module Spree
  describe Product do

    describe "associations" do
      it { should belong_to(:supplier) }
      it { should have_many(:product_distributions) }
    end

    describe "validations" do
      it "is valid when created from factory" do
        create(:product).should be_valid
      end

      it "requires a supplier" do
        product = create(:product)
        product.supplier = nil
        product.should_not be_valid
      end
    end

    describe "scopes" do
      describe "in_supplier" do
        it "shows products in supplier" do
          s1 = create(:supplier_enterprise)
          s2 = create(:supplier_enterprise)
          p1 = create(:product, supplier: s1)
          p2 = create(:product, supplier: s2)
          Product.in_supplier(s1).should == [p1]
        end
      end

      describe "in_distributor" do
        it "shows products in product distribution" do
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product, distributors: [d1])
          p2 = create(:product, distributors: [d2])
          Product.in_distributor(d1).should == [p1]
        end

        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          Product.in_distributor(d1).should == [p1]
        end

        it "shows products in order cycle distribution by variant" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          v1 = create(:variant, product: p1)
          p2 = create(:product)
          v2 = create(:variant, product: p2)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [v1])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [v2])
          Product.in_distributor(d1).should == [p1]
        end

        it "doesn't show products listed in the incoming exchange only", :future => true do
          s = create(:supplier_enterprise)
          c = create(:distributor_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product)
          oc = create(:simple_order_cycle, coordinator: c, suppliers: [s], distributors: [d])
          ex = oc.exchanges.incoming.first
          ex.variants << p.master

          Product.in_distributor(d).should be_empty
        end

        it "shows products in both without duplicates" do
          s = create(:supplier_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product, distributors: [d])
          create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
          Product.in_distributor(d).should == [p]
        end
      end

      describe "in_product_distribution_by" do
        it "shows products in product distribution" do
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product, distributors: [d1])
          p2 = create(:product, distributors: [d2])
          Product.in_product_distribution_by(d1).should == [p1]
        end

        it "does not show products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          Product.in_product_distribution_by(d1).should == []
        end
      end

      describe "in_supplier_or_distributor" do
        it "shows products in supplier" do
          s1 = create(:supplier_enterprise)
          s2 = create(:supplier_enterprise)
          p1 = create(:product, supplier: s1)
          p2 = create(:product, supplier: s2)
          Product.in_supplier_or_distributor(s1).should == [p1]
        end

        it "shows products in product distribution" do
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product, distributors: [d1])
          p2 = create(:product, distributors: [d2])
          Product.in_supplier_or_distributor(d1).should == [p1]
        end

        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          Product.in_supplier_or_distributor(d1).should == [p1]
        end

        it "shows products in all three without duplicates" do
          s = create(:supplier_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product, supplier: s, distributors: [d])
          create(:simple_order_cycle, suppliers: [s], distributors: [d], variants: [p.master])
          [s, d].each { |e| Product.in_supplier_or_distributor(e).should == [p] }
        end
      end

      describe "in_order_cycle" do
        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          oc1 = create(:simple_order_cycle, suppliers: [s], distributors: [d1], variants: [p1.master])
          oc2 = create(:simple_order_cycle, suppliers: [s], distributors: [d2], variants: [p2.master])
          Product.in_order_cycle(oc1).should == [p1]
        end
      end

      describe "access roles" do
        before(:each) do
          @e1 = create(:enterprise)
          @e2 = create(:enterprise)
          @p1 = create(:product, supplier: @e1)
          @p2 = create(:product, supplier: @e2)
        end

        it "shows only products for given user" do
          user = create(:user)
          user.spree_roles = []
          @e1.enterprise_roles.build(user: user).save

          product = Product.managed_by user
          product.count.should == 1
          product.should include @p1
        end

        it "shows all products for admin user" do
          user = create(:admin_user)

          product = Product.managed_by user
          product.count.should == 2
          product.should include @p1
          product.should include @p2
        end
      end
    end

    describe "finders" do
      it "finds the product distribution for a particular distributor" do
        distributor = create(:distributor_enterprise)
        product = create(:product)
        product_distribution = create(:product_distribution, product: product, distributor: distributor)
        product.product_distribution_for(distributor).should == product_distribution
      end
    end

    describe "membership" do
      it "queries its membership of a particular product distribution" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p = create(:product, distributors: [d1])

        p.should be_in_distributor d1
        p.should_not be_in_distributor d2
      end

      it "queries its membership of a particular order cycle distribution" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:order_cycle, :distributors => [d1], :variants => [p1.master])
        oc2 = create(:order_cycle, :distributors => [d2], :variants => [p2.master])

        p1.should be_in_distributor d1
        p1.should_not be_in_distributor d2
      end

      it "queries its membership of a particular order cycle" do
        d1 = create(:distributor_enterprise)
        d2 = create(:distributor_enterprise)
        p1 = create(:product)
        p2 = create(:product)
        oc1 = create(:order_cycle, :distributors => [d1], :variants => [p1.master])
        oc2 = create(:order_cycle, :distributors => [d2], :variants => [p2.master])

        p1.should be_in_order_cycle oc1
        p1.should_not be_in_order_cycle oc2
      end
    end
  end
end
