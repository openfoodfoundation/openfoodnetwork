require 'spec_helper'

module OpenFoodNetwork
  describe ProductsAndInventoryReport do
    context "As a site admin" do
      let(:user) do 
        user = create(:user)
        user.spree_roles << Spree::Role.find_or_create_by_name!("admin")
        user
      end
      subject do
        ProductsAndInventoryReport.new user
      end

      it "Should return headers" do
        subject.header.should == ["Supplier", "Product", "SKU", "Variant", "On Hand", "Price"]
      end

      it "should build a table from a list of variants" do
        variant = double(:variant, sku: "sku",
                         options_text: "Variant Name",
                         count_on_hand: 10,
                         price: 100)
        variant.stub_chain(:product, :supplier, :name).and_return("Supplier")
        variant.stub_chain(:product, :name).and_return("Product Name")
        subject.stub(:variants).and_return [variant]
        subject.table.should == [[
          "Supplier",
          "Product Name",
          "sku",
          "Variant Name",
          10,
          100]]
      end

      it "fetches variants for some params" do
        subject.should_receive(:child_variants).and_return ["children"]
        subject.should_receive(:master_variants).and_return ["masters"]
        subject.should_receive(:filter).with(['children']).and_return ["filter_children"]
        subject.should_receive(:filter).with(['masters']).and_return ["filter_masters"]
        subject.variants.should == ["filter_children", "filter_masters"]
      end
    end

    context "As an enterprise user" do
      let(:supplier) { create(:supplier_enterprise) }
      let(:enterprise_user) do 
        user = create(:user)
        user.enterprise_roles.create(enterprise: supplier)
        user.spree_roles = []
        user.save!
        user
      end
      subject do
        ProductsAndInventoryReport.new enterprise_user
      end
      describe "fetching child variants" do
        it "returns some variants" do
          product1 = create(:simple_product, supplier: supplier)
          variant_1 = create(:variant, product: product1)
          variant_2 = create(:variant, product: product1)

          subject.child_variants.sort.should == [variant_1, variant_2].sort
        end

        it "should only return variants managed by the user" do
          product1 = create(:simple_product, supplier: create(:supplier_enterprise))
          product2 = create(:simple_product, supplier: supplier)
          variant_1 = create(:variant, product: product1)
          variant_2 = create(:variant, product: product2)
          
          subject.child_variants.should == [variant_2]
        end
      end

      describe "fetching master variants" do
        it "should only return variants managed by the user" do
          product1 = create(:simple_product, supplier: create(:supplier_enterprise))
          product2 = create(:simple_product, supplier: supplier)
          
          subject.master_variants.should == [product2.master]
        end

        it "doesn't return master variants with siblings" do
          product = create(:simple_product, supplier: supplier)
          create(:variant, product: product)  
          
          subject.master_variants.should be_empty 
        end
      end

      describe "Filtering variants" do
        let(:variants) { Spree::Variant.scoped.joins(:product) }
        it "should return unfiltered variants sans-params" do
          product1 = create(:simple_product, supplier: supplier, on_hand: 99)
          product2 = create(:simple_product, supplier: supplier, on_hand: 0)
          subject.filter(Spree::Variant.scoped).should == [product1.master, product2.master]
        end
        describe "based on report type" do
          it "returns only variants on hand" do
            product1 = create(:simple_product, supplier: supplier, on_hand: 99)
            product2 = create(:simple_product, supplier: supplier, on_hand: 0)

            subject.stub(:params).and_return(report_type: 'inventory')
            subject.filter(variants).should == [product1.master]
          end
        end
        it "filters to a specific supplier" do
          supplier2 = create(:supplier_enterprise)
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier2)

          subject.stub(:params).and_return(supplier_id: supplier.id)
          subject.filter(variants).should == [product1.master]
        end
        it "filters to a specific distributor" do
          distributor = create(:distributor_enterprise)
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier, distributors: [distributor])

          subject.stub(:params).and_return(distributor_id: distributor.id)
          subject.filter(variants).should == [product2.master]
        end
        it "filters to a specific order cycle" do
          distributor = create(:distributor_enterprise)
          product1 = create(:simple_product, supplier: supplier, distributors: [distributor])
          product2 = create(:simple_product, supplier: supplier, distributors: [distributor])
          order_cycle = create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], variants: [product1.master])

          subject.stub(:params).and_return(order_cycle_id: order_cycle.id)
          subject.filter(variants).should == [product1.master]
        end
      end
    end
  end
end
