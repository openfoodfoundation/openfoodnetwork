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
      # Other things to test:
      # - no duplicates
      # - use 1.9 hash syntax

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
          p1 = create(:product, :distributors => [d1])
          p2 = create(:product, :distributors => [d2])
          Product.in_distributor(d1).should == [p1]
        end

        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, :suppliers => [s], :distributors => [d1], :variants => [p1.master])
          create(:simple_order_cycle, :suppliers => [s], :distributors => [d2], :variants => [p2.master])
          Product.in_distributor(d1).should == [p1]
        end

        it "shows products in both without duplicates" do
          s = create(:supplier_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product, :distributors => [d])
          create(:simple_order_cycle, :suppliers => [s], :distributors => [d], :variants => [p.master])
          Product.in_distributor(d).should == [p]
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
          p1 = create(:product, :distributors => [d1])
          p2 = create(:product, :distributors => [d2])
          Product.in_supplier_or_distributor(d1).should == [p1]
        end

        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          create(:simple_order_cycle, :suppliers => [s], :distributors => [d1], :variants => [p1.master])
          create(:simple_order_cycle, :suppliers => [s], :distributors => [d2], :variants => [p2.master])
          Product.in_supplier_or_distributor(d1).should == [p1]
        end

        it "shows products in all three without duplicates" do
          s = create(:supplier_enterprise)
          d = create(:distributor_enterprise)
          p = create(:product, supplier: s, distributors: [d])
          create(:simple_order_cycle, :suppliers => [s], :distributors => [d], :variants => [p.master])
          Product.in_supplier_or_distributor(d).should == [p]
        end
      end

      describe "in_order_cycle" do
        it "shows products in order cycle distribution" do
          s = create(:supplier_enterprise)
          d1 = create(:distributor_enterprise)
          d2 = create(:distributor_enterprise)
          p1 = create(:product)
          p2 = create(:product)
          oc1 = create(:simple_order_cycle, :suppliers => [s], :distributors => [d1], :variants => [p1.master])
          oc2 = create(:simple_order_cycle, :suppliers => [s], :distributors => [d2], :variants => [p2.master])
          Product.in_order_cycle(oc1).should == [p1]
        end
      end


      #  describe "in_order_cycle_distributor" do
      #    it "finds products listed by variant" do
      #      s = create(:supplier_enterprise)
      #      d = create(:distributor_enterprise)
      #      p = create(:product)
      #      v = create(:variant, :product => p)
      #      create(:simple_order_cycle, :suppliers => [s], :distributors => [d], :variants => [v])
      #      Product.in_order_cycle_distributor(d).should == [p]
      #    end

      #    it "doesn't show products listed in the incoming exchange only" do
      #      s = create(:supplier_enterprise)
      #      d = create(:distributor_enterprise)
      #      p = create(:product)
      #      oc = create(:simple_order_cycle, :coordinator => d, :suppliers => [s], :distributors => [d])
      #      ex = oc.exchanges.where(:receiver_id => oc.coordinator_id).first
      #      ex.variants << p.master

      #      Product.in_order_cycle_distributor(d).should be_empty
      #    end
      #  end

      # describe "in_supplier_or_distributor" do
      #    it "shows each product once when it is distributed by many distributors" do
      #      s = create(:supplier_enterprise)
      #      d1 = create(:distributor_enterprise)
      #      d2 = create(:distributor_enterprise)
      #      d3 = create(:distributor_enterprise)
      #      p = create(:product, :supplier => s, :distributors => [d1, d2, d3])

      #      [s, d1, d2, d3].each do |enterprise|
      #        Product.in_supplier_or_distributor(enterprise).should == [p]
      #      end
      #    end
      #  end

      #  describe "in_supplier_or_order_cycle_distributor" do
      #    it "shows each product once when it is distributed by many distributors" do
      #      s = create(:supplier_enterprise)
      #      d1 = create(:distributor_enterprise)
      #      d2 = create(:distributor_enterprise)
      #      d3 = create(:distributor_enterprise)
      #      p = create(:product, :supplier => s)

      #      create(:simple_order_cycle, :distributors => [d1, d2, d3], :variants => [p.master])
      #      create(:simple_order_cycle, :distributors => [d1], :variants => [p.master])

      #      [s, d1, d2, d3].each do |enterprise|
      #        Product.in_supplier_or_order_cycle_distributor(enterprise).should == [p]
      #      end
      #    end
      #  end
    end

    describe "finders" do
      it "finds the shipping method for a particular distributor" do
        shipping_method = create(:shipping_method)
        distributor = create(:distributor_enterprise)
        product = create(:product)
        product_distribution = create(:product_distribution, :product => product, :distributor => distributor, :shipping_method => shipping_method)
        product.shipping_method_for_distributor(distributor).should == shipping_method
      end

      it "raises an error if distributor is not found" do
        distributor = create(:distributor_enterprise)
        product = create(:product)
        expect do
          product.shipping_method_for_distributor(distributor)
        end.to raise_error "This product is not available through that distributor"
      end
    end
  end
end
