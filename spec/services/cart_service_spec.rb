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
          ActionController::Parameters.new(
            { variants: { variant.id.to_s => { quantity: '1', max_quantity: '2' } } }
          )
        )
        li = order.find_line_item_by_variant(variant)
        expect(li).to be
        expect(li.quantity).to eq(1)
        expect(li.max_quantity).to eq(2)
        expect(li.final_weight_volume).to eq(1.0)
      end

      context "updating an existing variant" do
        before do
          order.contents.update_or_create(variant, { quantity: 1, max_quantity: 2 })
        end

        it "updates a variant's quantity, max quantity and final_weight_volume" do
          cart_service.populate(
            ActionController::Parameters.new(
              { variants: { variant.id.to_s => { quantity: '2', max_quantity: '3' } } }
            )
          )

          li = order.find_line_item_by_variant(variant)
          expect(li).to be
          expect(li.quantity).to eq(2)
          expect(li.max_quantity).to eq(3)
          expect(li.final_weight_volume).to eq(2.0)
        end

        it "removes a variant" do
          cart_service.populate(
            ActionController::Parameters.new(
              { variants: { variant.id.to_s => { quantity: '0' } } }
            )
          )
          order.line_items.reload
          li = order.find_line_item_by_variant(variant)
          expect(li).not_to be
        end
      end

      context "when a variant has been soft-deleted" do
        let(:relevant_line_item) { order.reload.find_line_item_by_variant(variant) }

        describe "when the soft-deleted variant is not in the cart yet" do
          it "does not add the deleted variant to the cart" do
            variant.delete

            cart_service.populate(
              ActionController::Parameters.new(
                { variants: { variant.id.to_s => { quantity: '2' } } }
              )
            )

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

            cart_service.populate(
              ActionController::Parameters.new(
                { variants: { variant.id.to_s => { quantity: '3' } } }
              )
            )

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
      variant_data = { variant_id: variant.id, quantity: 2 }

      expect(cart_service).to receive(:line_item_for_variant).with(variant).and_return(nil)
      expect(cart_service.send(:varies_from_cart, variant_data, variant )).to be true
    end

    it "returns true when item is not in cart and a max_quantity is specified" do
      variant_data = { variant_id: variant.id, quantity: 0, max_quantity: 2 }

      expect(cart_service).to receive(:line_item_for_variant).with(variant).and_return(nil)
      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be true
    end

    it "returns false when item is not in cart and no quantity or max_quantity are specified" do
      variant_data = { variant_id: variant.id, quantity: 0 }

      expect(cart_service).to receive(:line_item_for_variant).with(variant).and_return(nil)
      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be false
    end

    it "returns true when quantity varies" do
      variant_data = { variant_id: variant.id, quantity: 2 }
      line_item = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant) { line_item }

      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be true
    end

    it "returns true when max_quantity varies" do
      variant_data = { variant_id: variant.id, quantity: 1, max_quantity: 3 }
      line_item = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant) { line_item }

      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be true
    end

    it "returns false when max_quantity varies only in nil vs 0" do
      variant_data = { variant_id: variant.id, quantity: 1 }
      line_item = double(:line_item, quantity: 1, max_quantity: nil)
      allow(cart_service).to receive(:line_item_for_variant) { line_item }

      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be false
    end

    it "returns false when both are specified and neither varies" do
      variant_data = { variant_id: variant.id, quantity: 1, max_quantity: 2 }
      line_item = double(:line_item, quantity: 1, max_quantity: 2)
      allow(cart_service).to receive(:line_item_for_variant) { line_item }

      expect(cart_service.send(:varies_from_cart, variant_data, variant)).to be false
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
      expect(order).to receive_message_chain(:contents, :update_or_create).
        with(variant, { quantity: quantity, max_quantity: nil })

      cart_service.send(:attempt_cart_add, variant, quantity)
    end

    it "filters quantities through #final_quantities" do
      expect(cart_service).to receive(:final_quantities).with(variant, 123, 123).
        and_return({ quantity: 5, max_quantity: 5 })

      allow(cart_service).to receive(:check_order_cycle_provided) { true }
      allow(cart_service).to receive(:check_variant_available_under_distribution) { true }

      expect(order).to receive_message_chain(:contents, :update_or_create).
        with(variant, { quantity: 5, max_quantity: 5 })

      cart_service.send(:attempt_cart_add, variant, quantity, quantity)
    end

    it "removes variants which have become out of stock" do
      expect(cart_service).to receive(:final_quantities).with(variant, 123, 123).
        and_return({ quantity: 0, max_quantity: 0 })

      allow(cart_service).to receive(:check_order_cycle_provided) { true }
      allow(cart_service).to receive(:check_variant_available_under_distribution) { true }

      expect(cart_service).to receive(:cart_add).with(variant, 123, 123).and_call_original
      expect(order).to receive_message_chain(:contents, :remove).with(variant)

      cart_service.send(:attempt_cart_add, variant, quantity, quantity)
    end
  end

  describe "#final_quantities" do
    let(:v) { double(:variant, on_hand: 10) }

    context "when backorders are not allowed" do
      before do
        expect(v).to receive(:on_demand).and_return(false)
      end

      context "getting quantity and max_quantity" do
        it "returns full amount when available" do
          expect(cart_service.send(:final_quantities, v, 5, nil)).
            to eq({ quantity: 5, max_quantity: nil })
        end

        it "returns a limited amount when not entirely available" do
          expect(cart_service.send(:final_quantities, v, 15, nil)).
            to eq({ quantity: 10, max_quantity: nil })
        end
      end

      context "when max_quantity is provided" do
        it "returns full amount when available" do
          expect(cart_service.send(:final_quantities, v, 5, 6)).
            to eq({ quantity: 5, max_quantity: 6 })
        end

        it "also returns the full amount when not entirely available" do
          expect(cart_service.send(:final_quantities, v, 15, 16)).
            to eq({ quantity: 10, max_quantity: 16 })
        end
      end
    end

    context "when variant is on_demand" do
      before do
        expect(v).to receive(:on_demand).and_return(true)
      end

      it "does not limit quantity" do
        expect(cart_service.send(:final_quantities, v, 15, nil)).
          to eq({ quantity: 15, max_quantity: nil })
      end

      it "does not limit max_quantity" do
        expect(cart_service.send(:final_quantities, v, 15, 16)).
          to eq({ quantity: 15, max_quantity: 16 })
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
        cart_service.instance_variable_set :@order_cycle, double(:order_cycle)
        expect(cart_service.send(:check_order_cycle_provided)).to be true
      end
    end

    describe "checking variant is available under the distributor" do
      let(:product) { double(:product) }
      let(:variant) { double(:variant, product: product) }
      let(:order_cycle_distributed_variants) { double(:order_cycle_distributed_variants) }

      before do
        expect(OrderCycleDistributedVariants)
          .to receive(:new).with(234, 123).and_return(order_cycle_distributed_variants)
        cart_service.instance_eval { @distributor = 123; @order_cycle = 234 }
      end

      it "delegates to OrderCycleDistributedVariants, returning true when available" do
        expect(order_cycle_distributed_variants).to receive(:available_variants)
          .and_return([variant])

        expect(cart_service.send(:check_variant_available_under_distribution, variant)).to be true
        expect(cart_service.errors).to be_empty
      end

      it "delegates to OrderCycleDistributedVariants, returning false and erroring otherwise" do
        expect(order_cycle_distributed_variants).to receive(:available_variants).and_return([])

        expect(cart_service.send(:check_variant_available_under_distribution, variant)).to be false
        expect(cart_service.errors.to_a)
          .to eq(["That product is not available from the chosen distributor or order cycle."])
      end
    end
  end
end
