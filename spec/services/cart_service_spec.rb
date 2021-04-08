# frozen_string_literal: true

require 'spec_helper'

describe CartService do
  let(:order) { double(:order, id: 123) }
  let(:currency) { "EUR" }
  let(:params) { {} }
  let(:distributor) { double(:distributor) }
  let(:order_cycle) { double(:order_cycle) }
  let(:cart_service) { CartService.new(order) }

  before do
    allow(order).to receive(:currency).and_return( currency )
  end

  context "end-to-end" do
    let(:order) { create(:order, distributor: distributor, order_cycle: order_cycle) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:order_cycle) {
      create(:simple_order_cycle, distributors: [distributor],
                                  variants: [variant])
    }
    let(:cart_service) { CartService.new(order) }
    let(:variant) { create(:variant) }

    describe "#populate" do
      it "adds a variant" do
        cart_service.populate(
          ActionController::Parameters.new({ variants: { variant.id.to_s => { quantity: '1',
                                                                              max_quantity: '2' } } }),
          true
        )
        li = order.find_line_item_by_variant(variant)
        expect(li).to be
        expect(li.quantity).to eq(1)
        expect(li.max_quantity).to eq(2)
        expect(li.final_weight_volume).to eq(1.0)
      end

      it "updates a variant's quantity, max quantity and final_weight_volume" do
        order.add_variant variant, 1, 2

        cart_service.populate(
          ActionController::Parameters.new({ variants: { variant.id.to_s => { quantity: '2',
                                                                              max_quantity: '3' } } }),
          true
        )
        li = order.find_line_item_by_variant(variant)
        expect(li).to be
        expect(li.quantity).to eq(2)
        expect(li.max_quantity).to eq(3)
        expect(li.final_weight_volume).to eq(2.0)
      end

      it "removes a variant" do
        order.add_variant variant, 1, 2

        cart_service.populate(ActionController::Parameters.new({ variants: {} }), true)
        order.line_items.reload
        li = order.find_line_item_by_variant(variant)
        expect(li).not_to be
      end

      context "when a variant has been soft-deleted" do
        let(:relevant_line_item) { order.reload.find_line_item_by_variant(variant) }

        describe "when the soft-deleted variant is not in the cart yet" do
          it "does not add the deleted variant to the cart" do
            variant.delete

            cart_service.populate(ActionController::Parameters.new({ variants: { variant.id.to_s => { quantity: '2' } } }), true)

            expect(relevant_line_item).to be_nil
            expect(cart_service.errors.count).to be 0
          end
        end

        describe "when the soft-deleted variant is already in the cart" do
          let!(:existing_line_item) {
            create(:line_item, variant: variant, quantity: 2, order: order)
          }

          it "removes the line_item from the cart" do
            variant.delete

            cart_service.populate(ActionController::Parameters.new({ variants: { variant.id.to_s => { quantity: '3' } } }), true)

            expect(Spree::LineItem.where(id: relevant_line_item).first).to be_nil
            expect(cart_service.errors.count).to be 0
          end
        end
      end
    end
  end

  describe "varies_from_cart" do
    let!(:variant) { create(:variant) }

    it "returns true when item is not in cart and a quantity is specified" do
      variant_data = { variant_id: variant.id, quantity: '2' }

      expect(cart_service).to receive(:line_item_for_variant).with(variant).and_return(nil)
      expect(cart_service.send(:varies_from_cart, variant_data, variant )).to be true
    end

    it "returns true when item is not in cart and a max_quantity is specified" do
      variant_data = { variant_id: variant.id, quantity: '0', max_quantity: '2' }

      expect(cart_service).to receive(:line_item_for_variant).with(variant).and_return(nil)
      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be true
    end

    it "returns false when item is not in cart and no quantity or max_quantity are specified" do
      variant_data = { variant_id: variant.id, quantity: '0' }

      expect(cart_service).to receive(:line_item_for_variant).with(variant).and_return(nil)
      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be false
    end

    it "returns true when quantity varies" do
      variant_data = { variant_id: variant.id, quantity: '2' }
      line_item = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant) { line_item }

      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be true
    end

    it "returns true when max_quantity varies" do
      variant_data = { variant_id: variant.id, quantity: '1', max_quantity: '3' }
      line_item = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant) { line_item }

      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be true
    end

    it "returns false when max_quantity varies only in nil vs 0" do
      variant_data = { variant_id: variant.id, quantity: '1' }
      line_item = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant) { line_item }

      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be false
    end

    it "returns false when both are specified and neither varies" do
      variant_data = { variant_id: variant.id, quantity: '1', max_quantity: '2' }
      line_item = double(:line_item, quantity: 1, max_quantity: 2)
      allow(cart_service).to receive(:line_item_for_variant) { line_item }

      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be false
    end
  end

  describe "variants_removed" do
    it "returns the variant ids when one is in the cart but not in those given" do
      allow(cart_service).to receive(:variant_ids_in_cart) { [123] }
      expect(cart_service.send(:variants_removed, [])).to eq([123])
    end

    it "returns nothing when all items in the cart are provided" do
      allow(cart_service).to receive(:variant_ids_in_cart) { [123] }
      expect(cart_service.send(:variants_removed, [{ variant_id: '123' }])).to eq([])
    end

    it "returns nothing when items are added to cart" do
      allow(cart_service).to receive(:variant_ids_in_cart) { [123] }
      expect(
        cart_service.send(:variants_removed, [{ variant_id: '123' }, { variant_id: '456' }])
      ).to eq([])
    end

    it "does not return duplicates" do
      allow(cart_service).to receive(:variant_ids_in_cart) { [123, 123] }
      expect(cart_service.send(:variants_removed, [])).to eq([123])
    end
  end

  describe "attempt_cart_add" do
    let!(:variant) { create(:variant, on_hand: 250) }
    let(:quantity) { 123 }

    before do
      allow(Spree::Variant).to receive(:find).and_return(variant)
      allow(VariantOverride).to receive(:for).and_return(nil)
    end

    it "performs additional validations" do
      expect(cart_service).to receive(:check_order_cycle_provided) { true }
      expect(cart_service).to receive(:check_variant_available_under_distribution).with(variant).
        and_return(true)
      expect(variant).to receive(:on_demand).and_return(false)
      expect(order).to receive(:add_variant).with(variant, quantity, nil, currency)

      cart_service.send(:attempt_cart_add, variant, quantity.to_s)
    end

    it "filters quantities through #quantities_to_add" do
      expect(cart_service).to receive(:quantities_to_add).with(variant, 123, 123).
        and_return([5, 5])

      allow(cart_service).to receive(:check_order_cycle_provided) { true }
      allow(cart_service).to receive(:check_variant_available_under_distribution) { true }

      expect(order).to receive(:add_variant).with(variant, 5, 5, currency)

      cart_service.send(:attempt_cart_add, variant, quantity.to_s, quantity.to_s)
    end

    it "removes variants which have become out of stock" do
      expect(cart_service).to receive(:quantities_to_add).with(variant, 123, 123).
        and_return([0, 0])

      allow(cart_service).to receive(:check_order_cycle_provided) { true }
      allow(cart_service).to receive(:check_variant_available_under_distribution) { true }

      expect(order).to receive(:remove_variant).with(variant)
      expect(order).to receive(:add_variant).never

      cart_service.send(:attempt_cart_add, variant, quantity.to_s, quantity.to_s)
    end
  end

  describe "quantities_to_add" do
    let(:v) { double(:variant, on_hand: 10) }

    context "when backorders are not allowed" do
      before do
        expect(v).to receive(:on_demand).and_return(false)
      end

      context "when max_quantity is not provided" do
        it "returns full amount when available" do
          expect(cart_service.send(:quantities_to_add, v, 5, nil)).to eq([5, nil])
        end

        it "returns a limited amount when not entirely available" do
          expect(cart_service.send(:quantities_to_add, v, 15, nil)).to eq([10, nil])
        end
      end

      context "when max_quantity is provided" do
        it "returns full amount when available" do
          expect(cart_service.send(:quantities_to_add, v, 5, 6)).to eq([5, 6])
        end

        it "also returns the full amount when not entirely available" do
          expect(cart_service.send(:quantities_to_add, v, 15, 16)).to eq([10, 16])
        end
      end
    end

    context "when variant is on_demand" do
      before do
        expect(v).to receive(:on_demand).and_return(true)
      end

      it "does not limit quantity" do
        expect(cart_service.send(:quantities_to_add, v, 15, nil)).to eq([15, nil])
      end

      it "does not limit max_quantity" do
        expect(cart_service.send(:quantities_to_add, v, 15, 16)).to eq([15, 16])
      end
    end
  end

  describe "validations" do
    describe "checking order cycle is provided for a variant, OR is not needed" do
      let(:variant) { double(:variant) }

      it "returns false and errors when order cycle is not provided" do
        expect(cart_service.send(:check_order_cycle_provided)).to be false
        expect(cart_service.errors.to_a).to eq(["Please choose an order cycle for this order."])
      end

      it "returns true when order cycle is provided" do
        cart_service.instance_variable_set :@order_cycle,  double(:order_cycle)
        expect(cart_service.send(:check_order_cycle_provided)).to be true
      end
    end

    describe "checking variant is available under the distributor" do
      let(:product) { double(:product) }
      let(:variant) { double(:variant, product: product) }
      let(:order_cycle_distributed_variants) { double(:order_cycle_distributed_variants) }

      before do
        expect(OrderCycleDistributedVariants).to receive(:new).with(234, 123).and_return(order_cycle_distributed_variants)
        cart_service.instance_eval { @distributor = 123; @order_cycle = 234 }
      end

      it "delegates to OrderCycleDistributedVariants, returning true when available" do
        expect(order_cycle_distributed_variants).to receive(:available_variants).and_return([variant])

        expect(cart_service.send(:check_variant_available_under_distribution, variant)).to be true
        expect(cart_service.errors).to be_empty
      end

      it "delegates to OrderCycleDistributedVariants, returning false and erroring otherwise" do
        expect(order_cycle_distributed_variants).to receive(:available_variants).and_return([])

        expect(cart_service.send(:check_variant_available_under_distribution, variant)).to be false
        expect(cart_service.errors.to_a).to eq(["That product is not available from the chosen distributor or order cycle."])
      end
    end
  end
end
