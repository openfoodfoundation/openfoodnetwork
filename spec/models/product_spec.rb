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

        it "doesn't show products listed in the incoming exchange only" do
          s = create(:supplier_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product)
          oc = create(:simple_order_cycle, coordinator: d, suppliers: [s], distributors: [d])
          ex = oc.exchanges.where(receiver_id: oc.coordinator_id).first
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
    end

    describe "finders" do
      it "finds the shipping method for a particular distributor" do
        shipping_method = create(:shipping_method)
        distributor = create(:distributor_enterprise)
        product = create(:product)
        product_distribution = create(:product_distribution, product: product, distributor: distributor, shipping_method: shipping_method)
        product.shipping_method_for_distributor(distributor).should == shipping_method
      end

      it "logs an error and returns an undefined shipping method if distributor is not found" do
        distributor = create(:distributor_enterprise)
        product = create(:product)

        Bugsnag.should_receive(:notify)

        product.shipping_method_for_distributor(distributor).should ==
          Spree::ShippingMethod.where("name != 'Delivery'").last
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
