require 'spec_helper'
require 'open_food_network/option_value_namer'

module Spree
  describe Variant do
    describe "scopes" do
      it "finds non-deleted variants" do
        v_not_deleted = create(:variant)
        v_deleted = create(:variant, deleted_at: Time.now)

        Spree::Variant.not_deleted.should     include v_not_deleted
        Spree::Variant.not_deleted.should_not include v_deleted
      end

      describe "finding variants in stock" do
        before do
          p = create(:product)
          @v_in_stock = create(:variant, product: p)
          @v_on_demand = create(:variant, product: p, on_demand: true)
          @v_no_stock = create(:variant, product: p)

          @v_in_stock.update_attribute(:count_on_hand, 1)
          @v_on_demand.update_attribute(:count_on_hand, 0)
          @v_no_stock.update_attribute(:count_on_hand, 0)
        end

        it "returns variants in stock or on demand, but not those that are neither" do
          Variant.where(is_master: false).in_stock.sort.should == [@v_in_stock, @v_on_demand].sort
        end
      end

      describe "finding variants in a distributor" do
        let!(:d1) { create(:distributor_enterprise) }
        let!(:d2) { create(:distributor_enterprise) }
        let!(:p1) { create(:simple_product) }
        let!(:p2) { create(:simple_product) }
        let!(:oc1) { create(:simple_order_cycle, distributors: [d1], variants: [p1.master]) }
        let!(:oc2) { create(:simple_order_cycle, distributors: [d2], variants: [p2.master]) }

        it "shows variants in an order cycle distribution" do
          Variant.in_distributor(d1).should == [p1.master]
        end

        it "doesn't show duplicates" do
          oc_dup = create(:simple_order_cycle, distributors: [d1], variants: [p1.master])
          Variant.in_distributor(d1).should == [p1.master]
        end
      end

      describe "finding variants in an order cycle" do
        let!(:d1) { create(:distributor_enterprise) }
        let!(:d2) { create(:distributor_enterprise) }
        let!(:p1) { create(:product) }
        let!(:p2) { create(:product) }
        let!(:oc1) { create(:simple_order_cycle, distributors: [d1], variants: [p1.master]) }
        let!(:oc2) { create(:simple_order_cycle, distributors: [d2], variants: [p2.master]) }

        it "shows variants in an order cycle" do
          Variant.in_order_cycle(oc1).should == [p1.master]
        end

        it "doesn't show duplicates" do
          ex = create(:exchange, order_cycle: oc1, sender: oc1.coordinator, receiver: d2)
          ex.variants << p1.master

          Variant.in_order_cycle(oc1).should == [p1.master]
        end
      end

    end

    describe "calculating the price with enterprise fees" do
      it "returns the price plus the fees" do
        distributor = double(:distributor)
        order_cycle = double(:order_cycle)

        variant = Variant.new price: 100
        variant.should_receive(:fees_for).with(distributor, order_cycle) { 23 }
        variant.price_with_fees(distributor, order_cycle).should == 123
      end
    end


    describe "calculating the fees" do
      it "delegates to EnterpriseFeeCalculator" do
        distributor = double(:distributor)
        order_cycle = double(:order_cycle)
        variant = Variant.new

        OpenFoodNetwork::EnterpriseFeeCalculator.any_instance.should_receive(:fees_for).with(variant) { 23 }

        variant.fees_for(distributor, order_cycle).should == 23
      end
    end


    context "when the product has variants" do
      let!(:product) { create(:simple_product) }
      let!(:variant) { create(:variant, product: product) }

      %w(weight volume).each do |unit|
        context "when the product's unit is #{unit}" do
          before do
            product.update_attribute :variant_unit, unit
            product.reload
          end

          it "is valid when unit value is set and unit description is not" do
            variant.unit_value = 1
            variant.unit_description = nil
            variant.should be_valid
          end

          it "is invalid when unit value is not set" do
            variant.unit_value = nil
            variant.should_not be_valid
          end

          it "has a valid master variant" do
            product.master.should be_valid
          end
        end
      end

      context "when the product's unit is items" do
        before do
          product.update_attribute :variant_unit, 'items'
          product.reload
        end

        it "is valid with only unit value set" do
          variant.unit_value = 1
          variant.unit_description = nil
          variant.should be_valid
        end

        it "is valid with only unit description set" do
          variant.unit_value = nil
          variant.unit_description = 'Medium'
          variant.should be_valid
        end

        it "is invalid when neither unit value nor unit description are set" do
          variant.unit_value = nil
          variant.unit_description = nil
          variant.should_not be_valid
        end

        it "has a valid master variant" do
          product.master.should be_valid
        end
      end
    end

    context "when the product does not have variants" do
      let(:product) { create(:simple_product, variant_unit: nil) }
      let(:variant) { product.master }

      it "does not require unit value or unit description when the product's unit is empty" do
        variant.unit_value = nil
        variant.unit_description = nil
        variant.should be_valid
      end
    end

    describe "unit value/description" do
      describe "getting name for display" do
        it "returns display_name if present" do
          v = create(:variant, display_name: "foo")
          v.name_to_display.should == "foo"
        end

        it "returns product name if display_name is empty" do
          v = create(:variant, product: create(:product))
          v.name_to_display.should == v.product.name
          v1 = create(:variant, display_name: "", product: create(:product))
          v1.name_to_display.should == v1.product.name
        end
      end

      describe "getting unit for display" do
        it "returns display_as if present" do
          v = create(:variant, display_as: "foo")
          v.unit_to_display.should == "foo"
        end

        it "returns options_text if display_as is blank" do
          v = create(:variant)
          v1 = create(:variant, display_as: "")
          v.stub(:options_text).and_return "ponies"
          v1.stub(:options_text).and_return "ponies"
          v.unit_to_display.should == "ponies"
          v1.unit_to_display.should == "ponies"
        end
      end

      describe "setting the variant's weight from the unit value" do
        it "sets the variant's weight when unit is weight" do
          p = create(:simple_product, variant_unit: nil, variant_unit_scale: nil)
          v = create(:variant, product: p, weight: nil)

          p.update_attributes! variant_unit: 'weight', variant_unit_scale: 1
          v.update_attributes! unit_value: 10, unit_description: 'foo'

          v.reload.weight.should == 0.01
        end

        it "does nothing when unit is not weight" do
          p = create(:simple_product, variant_unit: nil, variant_unit_scale: nil)
          v = create(:variant, product: p, weight: 123)

          p.update_attributes! variant_unit: 'volume', variant_unit_scale: 1
          v.update_attributes! unit_value: 10, unit_description: 'foo'

          v.reload.weight.should == 123
        end

        it "does nothing when unit_value is not set" do
          p = create(:simple_product, variant_unit: nil, variant_unit_scale: nil)
          v = create(:variant, product: p, weight: 123)

          p.update_attributes! variant_unit: 'weight', variant_unit_scale: 1

          # Although invalid, this calls the before_validation callback, which would
          # error if not handling unit_value == nil case
          v.update_attributes(unit_value: nil, unit_description: 'foo').should be_false

          v.reload.weight.should == 123
        end
      end

      context "when the variant initially has no value" do
        context "when the required option value does not exist" do
          let!(:p) { create(:simple_product, variant_unit: nil, variant_unit_scale: nil) }
          let!(:v) { create(:variant, product: p, unit_value: nil, unit_description: nil) }

          before do
            p.update_attributes!(variant_unit: 'weight', variant_unit_scale: 1)
            @ot = Spree::OptionType.find_by_name 'unit_weight'
          end

          it "creates the option value and assigns it to the variant" do
            expect {
              v.update_attributes!(unit_value: 10, unit_description: 'foo')
            }.to change(Spree::OptionValue, :count).by(1)

            ov = Spree::OptionValue.last
            ov.option_type.should == @ot
            ov.name.should == '10g foo'
            ov.presentation.should == '10g foo'

            v.option_values.should include ov
          end
        end

        context "when the required option value already exists" do
          let!(:p_orig) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
          let!(:v_orig) { create(:variant, product: p_orig, unit_value: 10, unit_description: 'foo') }

          let!(:p) { create(:simple_product, variant_unit: nil, variant_unit_scale: nil) }
          let!(:v) { create(:variant, product: p, unit_value: nil, unit_description: nil) }

          before do
            p.update_attributes!(variant_unit: 'weight', variant_unit_scale: 1)
            @ot = Spree::OptionType.find_by_name 'unit_weight'
          end

          it "looks up the option value and assigns it to the variant" do
            expect {
              v.update_attributes!(unit_value: 10, unit_description: 'foo')
            }.to change(Spree::OptionValue, :count).by(0)

            ov = v.option_values.last
            ov.option_type.should == @ot
            ov.name.should == '10g foo'
            ov.presentation.should == '10g foo'

            v_orig.option_values.should include ov
          end
        end
      end
      context "when the variant already has a value set (and all required option values exist)" do
        let!(:p0) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v0) { create(:variant, product: p0, unit_value: 10, unit_description: 'foo') }

        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar') }

        it "removes the old option value and assigns the new one" do
          ov_orig = v.option_values.last
          ov_new  = v0.option_values.last

          expect {
            v.update_attributes!(unit_value: 10, unit_description: 'foo')
          }.to change(Spree::OptionValue, :count).by(0)

          v.option_values.should_not include ov_orig
          v.option_values.should     include ov_new
        end
      end

      context "when the variant already has a value set (and all required option values exist)" do
        let!(:p0) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v0) { create(:variant, product: p0, unit_value: 10, unit_description: 'foo') }

        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar') }

        it "removes the old option value and assigns the new one" do
          ov_orig = v.option_values.last
          ov_new  = v0.option_values.last

          expect {
            v.update_attributes!(unit_value: 10, unit_description: 'foo')
          }.to change(Spree::OptionValue, :count).by(0)

          v.option_values.should_not include ov_orig
          v.option_values.should     include ov_new
        end
      end

      context "when the variant does not have a display_as value set" do
        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar', display_as: '') }

        it "requests the name of the new option_value from OptionValueName" do
          OpenFoodNetwork::OptionValueNamer.any_instance.should_receive(:name).exactly(1).times.and_call_original
          v.update_attributes(unit_value: 10, unit_description: 'foo')
          ov = v.option_values.last
          ov.name.should == "10g foo"
        end
      end

      context "when the variant has a display_as value set" do
        let!(:p) { create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1) }
        let!(:v) { create(:variant, product: p, unit_value: 5, unit_description: 'bar', display_as: 'FOOS!') }

        it "does not request the name of the new option_value from OptionValueName" do
          OpenFoodNetwork::OptionValueNamer.any_instance.should_not_receive(:name)
          v.update_attributes!(unit_value: 10, unit_description: 'foo')
          ov = v.option_values.last
          ov.name.should == "FOOS!"
        end
      end
    end

    describe "deleting unit option values" do
      before do
        p = create(:simple_product, variant_unit: 'weight', variant_unit_scale: 1)
        ot = Spree::OptionType.find_by_name 'unit_weight'
        @v = create(:variant, product: p)
      end

      it "removes option value associations for unit option types" do
        expect {
          @v.delete_unit_option_values
        }.to change(@v.option_values, :count).by(-1)
      end

      it "does not delete option values" do
        expect {
          @v.delete_unit_option_values
        }.to change(Spree::OptionValue, :count).by(0)
      end
    end
  end

  describe "destruction" do
    it "destroys exchange variants" do
      v = create(:variant)
      e = create(:exchange, variants: [v])

      v.destroy
      e.reload.variant_ids.should be_empty
    end
  end
end
