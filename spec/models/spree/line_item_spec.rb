require 'spec_helper'

module Spree
  describe LineItem do
    describe "scopes" do
      let(:o) { create(:order) }

      let(:s1) { create(:supplier_enterprise) }
      let(:s2) { create(:supplier_enterprise) }

      let(:p1) { create(:simple_product, supplier: s1) }
      let(:p2) { create(:simple_product, supplier: s2) }

      let(:li1) { create(:line_item, order: o, product: p1) }
      let(:li2) { create(:line_item, order: o, product: p2) }

      it "finds line items for products supplied by a particular enterprise" do
        LineItem.supplied_by(s1).should == [li1]
        LineItem.supplied_by(s2).should == [li2]
      end

      it "finds line items for products supplied by one of a number of enterprises" do
        LineItem.supplied_by_any([s1]).should == [li1]
        LineItem.supplied_by_any([s2]).should == [li2]
        LineItem.supplied_by_any([s1, s2]).should match_array [li1, li2]
      end

      describe "finding line items with and without tax" do
        let(:tax_rate) { create(:tax_rate, calculator: Spree::Calculator::DefaultTax.new) }
        let!(:adjustment1) { create(:adjustment, adjustable: li1, originator: tax_rate, label: "TR", amount: 123, included_tax: 10.00) }
        let!(:adjustment2) { create(:adjustment, adjustable: li1, originator: tax_rate, label: "TR", amount: 123, included_tax: 10.00) }

        before { li1; li2 }

        it "finds line items with tax" do
          LineItem.with_tax.should == [li1]
        end

        it "finds line items without tax" do
          LineItem.without_tax.should == [li2]
        end
      end
    end

    describe "capping quantity at stock level" do
      let!(:v) { create(:variant, on_demand: false, on_hand: 10) }
      let!(:li) { create(:line_item, variant: v, quantity: 10, max_quantity: 10) }

      before do
        v.update_attributes! on_hand: 5
      end

      it "caps quantity" do
        li.cap_quantity_at_stock!
        li.reload.quantity.should == 5
      end

      it "does not cap max_quantity" do
        li.cap_quantity_at_stock!
        li.reload.max_quantity.should == 10
      end

      it "works for products without max_quantity" do
        li.update_column :max_quantity, nil
        li.cap_quantity_at_stock!
        li.reload
        li.quantity.should == 5
        li.max_quantity.should be_nil
      end

      it "does nothing for on_demand items" do
        v.update_attributes! on_demand: true
        li.cap_quantity_at_stock!
        li.reload
        li.quantity.should == 10
        li.max_quantity.should == 10
      end

      context "when a variant override is in place" do
        let!(:hub) { create(:distributor_enterprise) }

        before { li.order.update_attributes(distributor_id: hub.id) }

        let!(:vo) { create(:variant_override, hub: hub, variant: v, count_on_hand: 2) }

        it "caps quantity to override stock level" do
          li.cap_quantity_at_stock!
          li.quantity.should == 2
        end
      end
    end

    describe "tracking stock when quantity is changed" do
      context "when the order is already complete" do
        let(:shop) { create(:distributor_enterprise)}
        let(:order) { create(:completed_order_with_totals, distributor: shop) }
        let!(:line_item) { order.reload.line_items.first }
        let!(:variant) { line_item.variant }

        context "when a variant override applies" do
          let!(:vo) { create(:variant_override, hub: shop, variant: variant, count_on_hand: 3 ) }

          it "draws stock from the variant override" do
            expect(vo.reload.count_on_hand).to eq 3
            expect{line_item.increment!(:quantity)}.to_not change{Spree::Variant.find(variant.id).on_hand}
            expect(vo.reload.count_on_hand).to eq 2
          end
        end

        context "when a variant override does not apply" do
          it "draws stock from the variant" do
            expect{line_item.increment!(:quantity)}.to change{Spree::Variant.find(variant.id).on_hand}.by(-1)
          end
        end
      end
    end

    describe "tracking stock when a line item is destroyed" do
      context "when the order is already complete" do
        let(:shop) { create(:distributor_enterprise)}
        let(:order) { create(:completed_order_with_totals, distributor: shop) }
        let!(:line_item) { order.reload.line_items.first }
        let!(:variant) { line_item.variant }

        context "when a variant override applies" do
          let!(:vo) { create(:variant_override, hub: shop, variant: variant, count_on_hand: 3 ) }

          it "restores stock to the variant override" do
            expect(vo.reload.count_on_hand).to eq 3
            expect{line_item.destroy}.to_not change{Spree::Variant.find(variant.id).on_hand}
            expect(vo.reload.count_on_hand).to eq 4
          end
        end

        context "when a variant override does not apply" do
          it "restores stock to the variant" do
            expect{line_item.destroy}.to change{Spree::Variant.find(variant.id).on_hand}.by(1)
          end
        end
      end
    end

    describe "determining if sufficient stock is present" do
      let!(:v) { create(:variant, on_demand: false, on_hand: 10) }
      let!(:li) { create(:line_item, variant: v, quantity: 5, max_quantity: 5) }
      let!(:hub) { create(:distributor_enterprise) }

      before do
        Spree::Config.set allow_backorders: false
        li.order.update_attributes(distributor_id: hub.id)
      end

      context "when no variant override is in place" do
        it "uses stock level on the variant" do
          expect(li.sufficient_stock?).to be_true
          v.update_attributes(on_hand: 4)
          expect(li.sufficient_stock?).to be_false
        end
      end

      context "when a variant override is in place" do
        let!(:vo) { create(:variant_override, hub: hub, variant: v, count_on_hand: 5) }

        it "uses stock level on the override" do
          expect(li.sufficient_stock?).to be_true
          v.update_attributes(on_hand: 4)
          expect(li.sufficient_stock?).to be_true
          vo.update_attributes(count_on_hand: 4)
          expect(li.sufficient_stock?).to be_false
        end
      end
    end

    describe "calculating price with adjustments" do
      it "does not return fractional cents" do
        li = LineItem.new

        li.stub(:price) { 55.55 }
        li.stub_chain(:order, :adjustments, :where, :sum) { 11.11 }
        li.stub(:quantity) { 2 }
        li.price_with_adjustments.should == 61.11
      end
    end

    describe "calculating amount with adjustments" do
      it "returns a value consistent with price_with_adjustments" do
        li = LineItem.new

        li.stub(:price) { 55.55 }
        li.stub_chain(:order, :adjustments, :where, :sum) { 11.11 }
        li.stub(:quantity) { 2 }
        li.amount_with_adjustments.should == 122.22
      end
    end

    describe "tax" do
      let(:li_no_tax)   { create(:line_item) }
      let(:li_tax)      { create(:line_item) }
      let(:tax_rate)    { create(:tax_rate, calculator: Spree::Calculator::DefaultTax.new) }
      let!(:adjustment) { create(:adjustment, adjustable: li_tax, originator: tax_rate, label: "TR", amount: 123, included_tax: 10.00) }

      context "checking if a line item has tax included" do
        it "returns true when it does" do
          expect(li_tax).to have_tax
        end

        it "returns false otherwise" do
          expect(li_no_tax).to_not have_tax
        end
      end

      context "calculating the amount of included tax" do
        it "returns the included tax when present" do
          expect(li_tax.included_tax).to eq 10.00
        end

        it "returns 0.00 otherwise" do
          expect(li_no_tax.included_tax).to eq 0.00
        end
      end
    end

    describe "unit value/description" do
      describe "inheriting units" do
        let!(:p) { create(:product, variant_unit: "weight", variant_unit_scale: 1, master: create(:variant, unit_value: 1000 )) }
        let!(:v) { p.variants.first }
        let!(:o) { create(:order) }

        context "on create" do
          context "when no final_weight_volume is set" do
            let(:li) { build(:line_item, order: o, variant: v, quantity: 3) }

            it "initializes final_weight_volume from the variant's unit_value" do
              expect(li.final_weight_volume).to be nil
              li.save
              expect(li.final_weight_volume).to eq 3000
            end
          end

          context "when a final_weight_volume has been set" do
            let(:li) { build(:line_item, order: o, variant: v, quantity: 3, final_weight_volume: 2000) }

            it "uses the changed value" do
              expect(li.final_weight_volume).to eq 2000
              li.save
              expect(li.final_weight_volume).to eq 2000
            end
          end
        end

        context "on save" do
          let!(:li) { create(:line_item, order: o, variant: v, quantity: 3) }

          before do
            expect(li.final_weight_volume).to eq 3000
          end

          context "when final_weight_volume is changed" do
            let(:attrs) { { final_weight_volume: 2000 } }

            context "and quantity is not changed" do
              before do
                li.update_attributes(attrs)
              end

              it "uses the value given" do
                expect(li.final_weight_volume).to eq 2000
              end
            end

            context "and quantity is changed" do
              before do
                attrs.merge!( quantity: 4 )
                li.update_attributes(attrs)
              end

              it "uses the value given" do
                expect(li.final_weight_volume).to eq 2000
              end
            end
          end

          context "when final_weight_volume is not changed" do
            let(:attrs) { { price: 3.00 } }

            context "and quantity is not changed" do
              before do
                li.update_attributes(attrs)
              end

              it "does not change final_weight_volume" do
                expect(li.final_weight_volume).to eq 3000
              end
            end

            context "and quantity is changed" do
              context "from > 0" do
                context "and a final_weight_volume has been set" do
                  before do
                    expect(li.final_weight_volume).to eq 3000
                    attrs.merge!( quantity: 4 )
                    li.update_attributes(attrs)
                  end

                  it "scales the final_weight_volume based on the change in quantity" do
                    expect(li.final_weight_volume).to eq 4000
                  end
                end

                context "and a final_weight_volume has not been set" do
                  before do
                    li.update_attributes(final_weight_volume: nil)
                    attrs.merge!( quantity: 1 )
                    li.update_attributes(attrs)
                  end

                  it "calculates a final_weight_volume from the variants unit_value" do
                    expect(li.final_weight_volume).to eq 1000
                  end
                end
              end

              context "from 0" do
                before { li.update_attributes(quantity: 0) }

                context "and a final_weight_volume has been set" do
                  before do
                    expect(li.final_weight_volume).to eq 0
                    attrs.merge!( quantity: 4 )
                    li.update_attributes(attrs)
                  end

                  it "recalculates a final_weight_volume from the variants unit_value" do
                    expect(li.final_weight_volume).to eq 4000
                  end
                end

                context "and a final_weight_volume has not been set" do
                  before do
                    li.update_attributes(final_weight_volume: nil)
                    attrs.merge!( quantity: 1 )
                    li.update_attributes(attrs)
                  end

                  it "calculates a final_weight_volume from the variants unit_value" do
                    expect(li.final_weight_volume).to eq 1000
                  end
                end
              end
            end
          end
        end
      end

      describe "generating the full name" do
        let(:li) { LineItem.new }

	      context "when display_name is blank" do
          before do
            li.stub(:unit_to_display) { 'unit_to_display' }
            li.stub(:display_name) { '' }
          end

          it "returns unit_to_display" do
            li.full_name.should == 'unit_to_display'
          end
        end

        context "when unit_to_display contains display_name" do
          before do
            li.stub(:unit_to_display) { '1kg Jar' }
            li.stub(:display_name) { '1kg' }
          end

          it "returns unit_to_display" do
            li.full_name.should == '1kg Jar'
          end
        end

        context "when display_name contains unit_to_display" do
          before do
            li.stub(:unit_to_display) { '10kg' }
            li.stub(:display_name) { '10kg Box' }
          end

          it "returns display_name" do
            li.full_name.should == '10kg Box'
          end
        end

        context "otherwise" do
          before do
            li.stub(:unit_to_display) { '1 Loaf' }
            li.stub(:display_name) { 'Spelt Sourdough' }
          end

          it "returns unit_to_display" do
            li.full_name.should == 'Spelt Sourdough (1 Loaf)'
          end
        end
      end

      describe "generating the product and variant name" do
        let(:li) { LineItem.new }
        let(:p) { double(:product, name: 'product') }
        before { allow(li).to receive(:product) { p } }

        context "when full_name starts with the product name" do
          before { allow(li).to receive(:full_name) { p.name + " - something" } }

          it "does not show the product name twice" do
            li.product_and_full_name.should == 'product - something'
          end
        end

        context "when full_name does not start with the product name" do
          before { allow(li).to receive(:full_name) { "display_name (unit)" } }

          it "prepends the product name to the full name" do
            li.product_and_full_name.should == 'product - display_name (unit)'
          end
        end
      end

      describe "getting name for display" do
        it "returns product name" do
          li = create(:line_item, product: create(:product))
          li.name_to_display.should == li.product.name
        end
      end

      describe "getting unit for display" do
        it "returns options_text" do
          li = create(:line_item)
          li.stub(:options_text).and_return "ponies"
          li.unit_to_display.should == "ponies"
        end
      end

      context "when the line_item already has a final_weight_volume set (and all required option values do not exist)" do
        let!(:p0) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p0, unit_value: 10, unit_description: 'bar') }

        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:li) { create(:line_item, product: p, final_weight_volume: 5) }

        it "removes the old option value and assigns the new one" do
          ov_orig = li.option_values.last
          ov_var  = v.option_values.last
          allow(li).to receive(:unit_description) { 'foo' }

          expect {
            li.update_attribute(:final_weight_volume, 10)
          }.to change(Spree::OptionValue, :count).by(1)

          li.option_values.should_not include ov_orig
          li.option_values.should_not include ov_var
          ov = li.option_values.last
          ov.name.should == "10g foo"
        end
      end

      context "when the variant already has a value set (and all required option values exist)" do
        let!(:p0) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p0, unit_value: 10, unit_description: 'bar') }

        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:li) { create(:line_item, product: p, final_weight_volume: 5) }

        it "removes the old option value and assigns the new one" do
          ov_orig = li.option_values.last
          ov_new  = v.option_values.last
          allow(li).to receive(:unit_description) { 'bar' }

          expect {
            li.update_attribute(:final_weight_volume, 10)
          }.to change(Spree::OptionValue, :count).by(0)

          li.option_values.should_not include ov_orig
          li.option_values.should     include ov_new
        end
      end
    end

    describe "deleting unit option values" do
      let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
      let!(:ot) { Spree::OptionType.find_by_name 'unit_weight' }
      let!(:li) { create(:line_item, product: p) }

      it "removes option value associations for unit option types" do
        expect {
          li.delete_unit_option_values
        }.to change(li.option_values, :count).by(-1)
      end

      it "does not delete option values" do
        expect {
          li.delete_unit_option_values
        }.to change(Spree::OptionValue, :count).by(0)
      end
    end
  end
end
