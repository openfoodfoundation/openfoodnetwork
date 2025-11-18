# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Enterprises::Delete do
  let!(:enterprise) { create(:enterprise) }
  let(:service) { described_class.new(enterprise: enterprise) }
  let(:user) { create(:user) }

  describe '#call' do
    context 'when enterprise has no variants' do
      it 'deletes the enterprise successfully' do
        expect { service.call }.to change { Enterprise.count }.by(-1)
      end

      it 'deletes associated distributor shipping methods' do
        create(:distributor_shipping_method, distributor: enterprise)

        expect { service.call }.to change { DistributorShippingMethod.count }.by(-2)
      end

      it 'deletes associated distributor payment methods' do
        create(:distributor_payment_method, distributor: enterprise)

        expect { service.call }.to change { DistributorPaymentMethod.count }.by(-2)
      end

      it 'deletes associated enterprise roles' do
        create(:enterprise_role, enterprise: enterprise, user: user)

        expect { service.call }.to change { EnterpriseRole.count }.by(-2)
      end
    end

    context 'when enterprise has variants without completed orders' do
      let!(:product) { create(:product, supplier_id: enterprise.id) }
      let!(:variant) { product.variants.first }

      before do
        # Create a cart order (not completed)
        order = create(:order, state: 'cart')
        create(:line_item, order: order, variant: variant)
      end

      it 'deletes the enterprise and its variants' do
        expect { service.call }.to change { Enterprise.count }.by(-1)
      end

      it 'deletes associated variants' do
        expect { service.call }.to change { Spree::Variant.with_deleted.count }.by(-1)
      end

      it 'deletes associated products' do
        expect { service.call }.to change { Spree::Product.with_deleted.count }.by(-1)
      end
    end

    context 'when enterprise has variants with completed orders' do
      let!(:product) { create(:product, supplier_id: enterprise.id) }
      let!(:variant) { product.variants.first }
      let!(:completed_order) { create(:order, state: 'complete') }
      let!(:line_item) { create(:line_item, order: completed_order, variant: variant) }

      it 'does not delete the enterprise' do
        expect { service.call }.not_to change { Enterprise.count }
      end

      it 'does not delete the variant' do
        expect { service.call }.not_to change { Spree::Variant.with_deleted.count }
      end

      it 'does not delete the product' do
        expect { service.call }.not_to change { Spree::Product.with_deleted.count }
      end

      it 'outputs skipping message' do
        expect { service.call }.to output(/Real deletion impossible/).to_stdout
      end
    end

    context 'when enterprise has mixed variants' do
      let!(:product1) { create(:product, supplier_id: enterprise.id) }
      let!(:variant1) { product1.variants.first }
      let!(:product2) { create(:product, supplier_id: enterprise.id) }
      let!(:variant2) { product2.variants.first }

      before do
        # One variant with completed order
        completed_order = create(:order, state: 'complete')
        create(:line_item, order: completed_order, variant: variant1)

        # One variant without completed order
        cart_order = create(:order, state: 'cart')
        create(:line_item, order: cart_order, variant: variant2)
      end

      it 'does not delete the enterprise due to completed order' do
        expect { service.call }.not_to change { Enterprise.count }
      end

      it 'skips deletion for variant with completed order' do
        expect { service.call }.not_to change { Spree::Variant.with_deleted.count }
      end
    end

    context 'when enterprise has soft-deleted variants' do
      let!(:product) { create(:product, supplier_id: enterprise.id) }
      let!(:variant) { product.variants.first }

      before do
        variant.destroy # Soft delete
      end

      it 'processes soft-deleted variants' do
        expect(enterprise.supplied_variants.with_deleted).to include(variant)
        expect { service.call }.to change { Enterprise.count }.by(-1)
      end
    end

    context 'database transaction behavior' do
      let!(:product) { create(:product, supplier_id: enterprise.id) }
      let!(:variant) { product.variants.first }

      it 'wraps deletion in a transaction' do
        expect(ActiveRecord::Base).to receive(:transaction).and_call_original
        service.call
      end

      context 'when an error occurs during deletion' do
        before do
          allow_any_instance_of(Spree::Variant).to receive(:really_destroy!).and_raise(StandardError)
        end

        it 'rolls back all changes' do
          expect { service.call }.to raise_error(StandardError)
          expect(Enterprise.exists?(enterprise.id)).to be true
        end
      end
    end
  end

  describe '#skipping_condition_for' do
    let!(:product) { create(:product, supplier_id: enterprise.id) }
    let!(:variant) { product.variants.first }

    context 'when variant has completed orders' do
      before do
        completed_order = create(:order, state: 'complete')
        create(:line_item, order: completed_order, variant: variant)
      end

      it 'returns true' do
        expect(service.send(:skipping_condition_for, variant)).to be true
      end
    end

    context 'when variant has no completed orders' do
      before do
        cart_order = create(:order, state: 'cart')
        create(:line_item, order: cart_order, variant: variant)
      end

      it 'returns false' do
        expect(service.send(:skipping_condition_for, variant)).to be false
      end
    end

    context 'when variant has no orders' do
      it 'returns false' do
        expect(service.send(:skipping_condition_for, variant)).to be false
      end
    end
  end

  describe '#delete_stock_movements_for' do
    let!(:product) { create(:product, supplier_id: enterprise.id) }
    let!(:variant) { product.variants.first }
    let!(:stock_item) { Spree::StockItem.create!(variant: variant) }
    let!(:stock_movement) { create(:stock_movement, stock_item: stock_item) }

    it 'deletes stock movements using raw SQL' do
      expect {
        service.send(:delete_stock_movements_for, stock_item)
      }.to change { Spree::StockMovement.where(stock_item_id: stock_item.id).count }.by(-1)
    end

    it 'uses sanitized SQL to prevent injection' do
      expect(ActiveRecord::Base).to receive(:sanitize_sql_array).and_call_original
      service.send(:delete_stock_movements_for, stock_item)
    end
  end

  describe '#delete_variants_related_data_for' do
    let!(:product) { create(:product, supplier_id: enterprise.id) }
    let!(:variant) { product.variants.first }
    let!(:stock_item) { Spree::StockItem.create!(variant: variant) }

    it 'deletes stock items' do
      expect {
        service.send(:delete_variants_related_data_for, variant)
      }.to change { Spree::StockItem.with_deleted.count }.by(-1)
    end

    it 'deletes the product' do
      expect {
        service.send(:delete_variants_related_data_for, variant)
      }.to change { Spree::Product.with_deleted.count }.by(-1)
    end

    it 'deletes the variant' do
      expect {
        service.send(:delete_variants_related_data_for, variant)
      }.to change { Spree::Variant.with_deleted.count }.by(-1)
    end
  end
end
