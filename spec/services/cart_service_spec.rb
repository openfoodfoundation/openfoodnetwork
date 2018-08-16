require 'spec_helper'

describe CartService do
  let(:order) { double(:order, id: 123) }
  let(:currency) { double(:currency) }
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
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor], variants: [v]) }
    let(:cart_service) { CartService.new(order) }
    let(:v) { create(:variant) }

    describe "populate" do
      it "adds a variant" do
        cart_service.populate({variants: {v.id.to_s => {quantity: '1', max_quantity: '2'}}}, true)
        li = order.find_line_item_by_variant(v)
        expect(li).to be
        expect(li.quantity).to eq(1)
        expect(li.max_quantity).to eq(2)
        expect(li.final_weight_volume).to eq(1.0)
      end

      it "updates a variant's quantity, max quantity and final_weight_volume" do
        order.add_variant v, 1, 2

        cart_service.populate({variants: {v.id.to_s => {quantity: '2', max_quantity: '3'}}}, true)
        li = order.find_line_item_by_variant(v)
        expect(li).to be
        expect(li.quantity).to eq(2)
        expect(li.max_quantity).to eq(3)
        expect(li.final_weight_volume).to eq(2.0)
      end

      it "removes a variant" do
        order.add_variant v, 1, 2

        cart_service.populate({variants: {}}, true)
        order.line_items(:reload)
        li = order.find_line_item_by_variant(v)
        expect(li).not_to be
      end
    end
  end

  describe "populate" do
    before do
      expect(cart_service).to receive(:distributor_and_order_cycle).
        and_return([distributor, order_cycle])
    end

    it "checks that distribution can supply all products in the cart" do
      expect(cart_service).to receive(:distribution_can_supply_products_in_cart).
        with(distributor, order_cycle).and_return(false)

      expect(cart_service.populate(params)).to be false
      expect(cart_service.errors.to_a).to eq(["That distributor or order cycle can't supply all the products in your cart. Please choose another."])
    end

    it "locks the order" do
      allow(cart_service).to receive(:distribution_can_supply_products_in_cart).and_return(true)
      expect(order).to receive(:with_lock)
      cart_service.populate(params, true)
    end

    it "attempts cart add with max_quantity" do
      allow(cart_service).to receive(:distribution_can_supply_products_in_cart).and_return true
      params = {variants: {"1" => {quantity: 1, max_quantity: 2}}}
      allow(order).to receive(:with_lock).and_yield
      allow(cart_service).to receive(:varies_from_cart) { true }
      allow(cart_service).to receive(:variants_removed) { [] }
      expect(cart_service).to receive(:attempt_cart_add).with("1", 1, 2).and_return true
      cart_service.populate(params, true)
    end
  end

  describe "varies_from_cart" do
    let(:variant) { double(:variant, id: 123) }

    it "returns true when item is not in cart and a quantity is specified" do
      expect(cart_service).to receive(:line_item_for_variant_id).with(variant.id).and_return(nil)
      expect(cart_service.send(:varies_from_cart, {variant_id: variant.id, quantity: '2'})).to be true
    end

    it "returns true when item is not in cart and a max_quantity is specified" do
      expect(cart_service).to receive(:line_item_for_variant_id).with(variant.id).and_return(nil)
      expect(cart_service.send(:varies_from_cart, {variant_id: variant.id, quantity: '0', max_quantity: '2'})).to be true
    end

    it "returns false when item is not in cart and no quantity or max_quantity are specified" do
      expect(cart_service).to receive(:line_item_for_variant_id).with(variant.id).and_return(nil)
      expect(cart_service.send(:varies_from_cart, {variant_id: variant.id, quantity: '0'})).to be false
    end

    it "returns true when quantity varies" do
      li = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant_id) { li }

      expect(cart_service.send(:varies_from_cart, {variant_id: variant.id, quantity: '2'})).to be true
    end

    it "returns true when max_quantity varies" do
      li = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant_id) { li }

      expect(cart_service.send(:varies_from_cart, {variant_id: variant.id, quantity: '1', max_quantity: '3'})).to be true
    end

    it "returns false when max_quantity varies only in nil vs 0" do
      li = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant_id) { li }

      expect(cart_service.send(:varies_from_cart, {variant_id: variant.id, quantity: '1'})).to be false
    end

    it "returns false when both are specified and neither varies" do
      li = double(:line_item, quantity: 1, max_quantity: 2)
      allow(cart_service).to receive(:line_item_for_variant_id) { li }

      expect(cart_service.send(:varies_from_cart, {variant_id: variant.id, quantity: '1', max_quantity: '2'})).to be false
    end
  end

  describe "variants_removed" do
    it "returns the variant ids when one is in the cart but not in those given" do
      allow(cart_service).to receive(:variant_ids_in_cart) { [123] }
      expect(cart_service.send(:variants_removed, [])).to eq([123])
    end

    it "returns nothing when all items in the cart are provided" do
      allow(cart_service).to receive(:variant_ids_in_cart) { [123] }
      expect(cart_service.send(:variants_removed, [{variant_id: '123'}])).to eq([])
    end

    it "returns nothing when items are added to cart" do
      allow(cart_service).to receive(:variant_ids_in_cart) { [123] }
      expect(cart_service.send(:variants_removed, [{variant_id: '123'}, {variant_id: '456'}])).to eq([])
    end

    it "does not return duplicates" do
      allow(cart_service).to receive(:variant_ids_in_cart) { [123, 123] }
      expect(cart_service.send(:variants_removed, [])).to eq([123])
    end
  end

  describe "attempt_cart_add" do
    let(:variant) { double(:variant, on_hand: 250) }
    let(:quantity) { 123 }

    before do
      allow(Spree::Variant).to receive(:find).and_return(variant)
      allow(VariantOverride).to receive(:for).and_return(nil)
    end

    it "performs additional validations" do
      expect(cart_service).to receive(:check_order_cycle_provided_for).with(variant).and_return(true)
      expect(cart_service).to receive(:check_variant_available_under_distribution).with(variant).
        and_return(true)
      expect(order).to receive(:add_variant).with(variant, quantity, nil, currency)

      cart_service.attempt_cart_add(333, quantity.to_s)
    end

    it "filters quantities through #quantities_to_add" do
      expect(cart_service).to receive(:quantities_to_add).with(variant, 123, 123).
        and_return([5, 5])

      allow(cart_service).to receive(:check_order_cycle_provided_for) { true }
      allow(cart_service).to receive(:check_variant_available_under_distribution) { true }

      expect(order).to receive(:add_variant).with(variant, 5, 5, currency)

      cart_service.attempt_cart_add(333, quantity.to_s, quantity.to_s)
    end

    it "removes variants which have become out of stock" do
      expect(cart_service).to receive(:quantities_to_add).with(variant, 123, 123).
        and_return([0, 0])

      allow(cart_service).to receive(:check_order_cycle_provided_for) { true }
      allow(cart_service).to receive(:check_variant_available_under_distribution) { true }

      expect(order).to receive(:remove_variant).with(variant)
      expect(order).to receive(:add_variant).never

      cart_service.attempt_cart_add(333, quantity.to_s, quantity.to_s)
    end
  end

  describe "quantities_to_add" do
    let(:v) { double(:variant, on_hand: 10) }

    context "when backorders are not allowed" do
      context "when max_quantity is not provided" do
        it "returns full amount when available" do
          expect(cart_service.quantities_to_add(v, 5, nil)).to eq([5, nil])
        end

        it "returns a limited amount when not entirely available" do
          expect(cart_service.quantities_to_add(v, 15, nil)).to eq([10, nil])
        end
      end

      context "when max_quantity is provided" do
        it "returns full amount when available" do
          expect(cart_service.quantities_to_add(v, 5, 6)).to eq([5, 6])
        end

        it "also returns the full amount when not entirely available" do
          expect(cart_service.quantities_to_add(v, 15, 16)).to eq([10, 16])
        end
      end
    end

    context "when backorders are allowed" do
      before do
        Spree::Config.allow_backorders = true
      end

      it "does not limit quantity" do
        expect(cart_service.quantities_to_add(v, 15, nil)).to eq([15, nil])
      end

      it "does not limit max_quantity" do
        expect(cart_service.quantities_to_add(v, 15, 16)).to eq([15, 16])
      end
    end
  end

  describe "validations" do
    describe "determining if distributor can supply products in cart" do
      it "delegates to DistributionChangeValidator" do
        dcv = double(:dcv)
        expect(dcv).to receive(:can_change_to_distribution?).with(distributor, order_cycle).and_return(true)
        expect(DistributionChangeValidator).to receive(:new).with(order).and_return(dcv)
        expect(cart_service.send(:distribution_can_supply_products_in_cart, distributor, order_cycle)).to be true
      end
    end

    describe "checking order cycle is provided for a variant, OR is not needed" do
      let(:variant) { double(:variant) }

      it "returns false and errors when order cycle is not provided and is required" do
        allow(cart_service).to receive(:order_cycle_required_for).and_return true
        expect(cart_service.send(:check_order_cycle_provided_for, variant)).to be false
        expect(cart_service.errors.to_a).to eq(["Please choose an order cycle for this order."])
      end
      it "returns true when order cycle is provided" do
        allow(cart_service).to receive(:order_cycle_required_for).and_return true
        cart_service.instance_variable_set :@order_cycle,  double(:order_cycle)
        expect(cart_service.send(:check_order_cycle_provided_for, variant)).to be true
      end
      it "returns true when order cycle is not required" do
        allow(cart_service).to receive(:order_cycle_required_for).and_return false
        expect(cart_service.send(:check_order_cycle_provided_for, variant)).to be true
      end
    end

    describe "checking variant is available under the distributor" do
      let(:product) { double(:product) }
      let(:variant) { double(:variant, product: product) }

      it "delegates to DistributionChangeValidator, returning true when available" do
        dcv = double(:dcv)
        expect(dcv).to receive(:variants_available_for_distribution).with(123, 234).and_return([variant])
        expect(DistributionChangeValidator).to receive(:new).with(order).and_return(dcv)
        cart_service.instance_eval { @distributor = 123; @order_cycle = 234 }
        expect(cart_service.send(:check_variant_available_under_distribution, variant)).to be true
        expect(cart_service.errors).to be_empty
      end

      it "delegates to DistributionChangeValidator, returning false and erroring otherwise" do
        dcv = double(:dcv)
        expect(dcv).to receive(:variants_available_for_distribution).with(123, 234).and_return([])
        expect(DistributionChangeValidator).to receive(:new).with(order).and_return(dcv)
        cart_service.instance_eval { @distributor = 123; @order_cycle = 234 }
        expect(cart_service.send(:check_variant_available_under_distribution, variant)).to be false
        expect(cart_service.errors.to_a).to eq(["That product is not available from the chosen distributor or order cycle."])
      end
    end
  end


  describe "support" do
    describe "checking if order cycle is required for a variant" do
      it "requires an order cycle when the product has no product distributions" do
        product = double(:product, product_distributions: [])
        variant = double(:variant, product: product)
        expect(cart_service.send(:order_cycle_required_for, variant)).to be true
      end

      it "does not require an order cycle when the product has product distributions" do
        product = double(:product, product_distributions: [1])
        variant = double(:variant, product: product)
        expect(cart_service.send(:order_cycle_required_for, variant)).to be false
      end
    end

    it "provides the distributor and order cycle for the order" do
      expect(order).to receive(:distributor).and_return(distributor)
      expect(order).to receive(:order_cycle).and_return(order_cycle)
      expect(cart_service.send(:distributor_and_order_cycle)).to eq([distributor,
                                                       order_cycle])
    end
  end
end
