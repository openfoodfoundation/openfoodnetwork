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
        subject.header.should == [
          "Supplier",
          "Producer Suburb",
          "Product",
          "Product Properties",
          "Taxons",
          "Variant Value",
          "Price",
          "Group Buy Unit Quantity",
          "Amount",
          "SKU"
        ]
      end

      it "should build a table from a list of variants" do
        variant = double(:variant, sku: "sku",
                        full_name: "Variant Name",
                        count_on_hand: 10,
                        price: 100)
        variant.stub_chain(:product, :supplier, :name).and_return("Supplier")
        variant.stub_chain(:product, :supplier, :address, :city).and_return("A city")
        variant.stub_chain(:product, :name).and_return("Product Name")
        variant.stub_chain(:product, :properties).and_return [double(name: "property1"), double(name: "property2")]
        variant.stub_chain(:product, :taxons).and_return [double(name: "taxon1"), double(name: "taxon2")]
        variant.stub_chain(:product, :group_buy_unit_size).and_return(21)
        subject.stub(:variants).and_return [variant]

        subject.table.should == [[
          "Supplier",
          "A city",
          "Product Name",
          "property1, property2",
          "taxon1, taxon2",
          "Variant Name",
          100,
          21,
          "",
          "sku"
        ]]
      end

      it "fetches variants for some params" do
        subject.should_receive(:child_variants).and_return ["children"]
        subject.should_receive(:filter).with(['children']).and_return ["filter_children"]
        subject.variants.should == ["filter_children"]
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
          variant_1 = product1.variants.first
          variant_2 = create(:variant, product: product1)

          subject.child_variants.should match_array [variant_1, variant_2]
        end

        it "should only return variants managed by the user" do
          product1 = create(:simple_product, supplier: create(:supplier_enterprise))
          product2 = create(:simple_product, supplier: supplier)
          variant_1 = product1.variants.first
          variant_2 = product2.variants.first

          subject.child_variants.should == [variant_2]
        end
      end

      describe "Filtering variants" do
        let(:variants) { Spree::Variant.scoped.joins(:product).where(is_master: false) }
        it "should return unfiltered variants sans-params" do
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier)

          subject.filter(Spree::Variant.scoped).should match_array [product1.master, product1.variants.first, product2.master, product2.variants.first]
        end
        it "should filter deleted products" do
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier)
          product2.delete
          subject.filter(Spree::Variant.scoped).should match_array [product1.master, product1.variants.first]
        end
        describe "based on report type" do
          it "returns only variants on hand" do
            product1 = create(:simple_product, supplier: supplier, on_hand: 99)
            product2 = create(:simple_product, supplier: supplier, on_hand: 0)

            subject.stub(:params).and_return(report_type: 'inventory')
            subject.filter(variants).should == [product1.variants.first]
          end
        end
        it "filters to a specific supplier" do
          supplier2 = create(:supplier_enterprise)
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier2)

          subject.stub(:params).and_return(supplier_id: supplier.id)
          subject.filter(variants).should == [product1.variants.first]
        end
        it "filters to a specific distributor" do
          distributor = create(:distributor_enterprise)
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier)
          order_cycle = create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], variants: [product2.variants.first])

          subject.stub(:params).and_return(distributor_id: distributor.id)
          subject.filter(variants).should == [product2.variants.first]
        end
        it "filters to a specific order cycle" do
          distributor = create(:distributor_enterprise)
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier)
          order_cycle = create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], variants: [product1.variants.first])

          subject.stub(:params).and_return(order_cycle_id: order_cycle.id)
          subject.filter(variants).should == [product1.variants.first]
        end

        it "should do all the filters at once" do
          distributor = create(:distributor_enterprise)
          product1 = create(:simple_product, supplier: supplier)
          product2 = create(:simple_product, supplier: supplier)
          order_cycle = create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor], variants: [product1.variants.first])

          subject.stub(:params).and_return(
            order_cycle_id: order_cycle.id,
            supplier_id: supplier.id,
            distributor_id: distributor.id,
            report_type: 'inventory')
          subject.filter(variants)
        end
      end

      describe "fetching SKU for a variant" do
        let(:variant) { create(:variant) }
        let(:product) { variant.product }

        before { product.update_attribute(:sku, "Product SKU") }

        context "when the variant has an SKU set" do
          before { variant.update_attribute(:sku, "Variant SKU") }
          it "returns it" do
            expect(subject.send(:sku_for, variant)).to eq "Variant SKU"
          end
        end

        context "when the variant has bo SKU set" do
          before { variant.update_attribute(:sku, "") }

          it "returns the product's SKU" do
            expect(subject.send(:sku_for, variant)).to eq "Product SKU"
          end
        end
      end
    end
  end
end
