# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Enterprises::Delete do
  let!(:enterprise) { create(:enterprise) }
  let(:service) { described_class.new(enterprise: enterprise) }
  let(:user) { create(:user) }

  describe '#call' do
    context 'when enterprise has no variants' do
      it 'deletes successfully the enterprise and the direct relations' do
        create(:distributor_shipping_method, distributor: enterprise)
        create(:distributor_payment_method, distributor: enterprise)
        create(:enterprise_role, enterprise: enterprise, user: user)

        expect { service.call }
          .to change {
            Enterprise.where(id: enterprise.id).exists?
          }.from(true).to(false)
          .and change { DistributorShippingMethod.count }.by(-2)
          .and change { DistributorPaymentMethod.count }.by(-2)
          .and change { EnterpriseRole.count }.by(-2)
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

      it 'deletes the enterprise' do
        expect { service.call }.to change {
          Enterprise.where(id: enterprise.id).exists?
        }.from(true).to(false)
      end

      it 'deletes associated variants' do
        expect { service.call }.to change {
          Spree::Variant.with_deleted.where(id: variant.id).exists?
        }.from(true).to(false)
      end

      it 'deletes the associated product' do
        expect { service.call }.to change {
          Spree::Product.where(id: product.id).exists?
        }.from(true).to(false)
      end
    end

    context 'when enterprise has variants with completed orders' do
      let!(:product) { create(:product, supplier_id: enterprise.id) }
      let!(:variant) { product.variants.first }
      let!(:completed_order) { create(:order, state: 'complete') }
      let!(:line_item) { create(:line_item, order: completed_order, variant: variant) }

      it 'does not delete the enterprise' do
        expect { service.call }.not_to change { Enterprise.where(id: enterprise.id).exists? }
      end

      it 'does not delete the variant' do
        expect { service.call }.not_to change {
          Spree::Variant.where(id: variant.id).exists?
        }
      end

      it 'does not delete the product' do
        expect { service.call }.not_to change {
          Spree::Product.where(id: product.id).exists?
        }
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
        expect { service.call }.not_to change { Enterprise.where(id: enterprise.id).exists? }
      end

      it 'skips deletion for variant with completed order' do
        expect { service.call }.not_to change { Spree::Variant.where(id: variant1.id).exists? }
      end

      it 'does not delete the product related to the completed order' do
        expect { service.call }.not_to change {
          Spree::Product.where(id: product1.id).exists?
        }
      end

      it 'deletes the product related to the draft order' do
        expect { service.call }.not_to change { Spree::Product.where(id: product2.id).exists? }
      end
    end

    context 'when enterprise has soft-deleted variants' do
      let!(:product) { create(:product, supplier_id: enterprise.id) }
      let!(:variant) { product.variants.first }

      before do
        variant.destroy
      end

      it 'deletes really soft-deleted variants' do
        expect(enterprise.supplied_variants.with_deleted).to include(variant)
        expect { service.call }
          .to change { Enterprise.where(id: enterprise.id).exists? }.from(true).to(false)
          .and change {
                 Spree::Variant.with_deleted.where(id: variant.id).exists?
               }.from(true).to(false)
      end
    end

    context 'when enterprise has orders with products from other enterprises' do
      let(:other_enterprise) { create(:enterprise) }
      let!(:product) { create(:product, supplier_id: other_enterprise.id) }
      let!(:variant) { product.variants.first }

      context 'when no orders are completed' do
        it 'deletes the enterprise and the orders' do
          cart_order = create(:order, state: 'cart', distributor_id: enterprise.id)
          create(:line_item, order: cart_order, variant: variant)

          expect(other_enterprise.supplied_variants.with_deleted).to include(variant)
          expect { service.call }
            .to change { Enterprise.where(id: enterprise.id).exists? }.from(true).to(false)
            .and change {
                   Spree::Order.where(id: cart_order.id).exists?
                 }.from(true).to(false)
        end
      end

      context 'when at least one order is completed' do
        it 'skips deletion' do
          completed_order = create(:order, state: 'complete', distributor_id: enterprise.id)
          create(:line_item, order: completed_order, variant: variant)

          expect(other_enterprise.supplied_variants.with_deleted).to include(variant)
          expect { service.call }.not_to change { Enterprise.where(id: enterprise.id).exists? }
          expect { service.call }
            .not_to change { Spree::Order.where(id: completed_order.id).exists? }
        end
      end
    end

    context 'when enterprise has variant overrides with variants from other enterprises' do
      let(:other_enterprise) { create(:enterprise) }
      let!(:product) { create(:product, supplier_id: other_enterprise.id) }
      let!(:variant) { product.variants.first }
      let!(:variant_override) { variant.variant_overrides.create!(hub_id: enterprise.id) }

      context 'when no orders are completed' do
        it 'deletes the enterprise and the variant overrides' do
          cart_order = create(:order, state: 'cart', distributor_id: enterprise.id)
          create(:line_item, order: cart_order, variant: variant)

          expect(other_enterprise.supplied_variants.with_deleted).to include(variant)
          expect { service.call }
            .to change { Enterprise.where(id: enterprise.id).exists? }.from(true).to(false)
            .and change {
                   VariantOverride.where(id: variant_override.id).exists?
                 }.from(true).to(false)
        end
      end

      context 'when at least one order is completed' do
        it 'skips deletion' do
          completed_order = create(:order, state: 'complete', distributor_id: enterprise.id)
          create(:line_item, order: completed_order, variant: variant)

          expect(other_enterprise.supplied_variants.with_deleted).to include(variant)
          expect { service.call }.not_to change { Enterprise.where(id: enterprise.id).exists? }
          expect { service.call }
            .not_to change { VariantOverride.where(id: variant_override.id).exists? }
        end
      end
    end

    context 'when enterprise has linked order cycles' do
      let(:other_enterprise) { create(:enterprise) }
      let!(:product) { create(:product, supplier_id: other_enterprise.id) }
      let!(:variant) { product.variants.first }
      let!(:order_cycle) { create(:order_cycle, coordinator_id: enterprise.id) }

      context 'with no completed orders' do
        it 'deletes the enterprise and the related order cycle' do
          cart_order = create(
            :order, state: 'cart',
                    distributor_id: other_enterprise.id, order_cycle_id: order_cycle.id
          )
          create(:line_item, order: cart_order, variant: variant)

          expect { service.call }
            .to change { Enterprise.where(id: enterprise.id).exists? }.from(true).to(false)
            .and change {
                   OrderCycle.where(id: order_cycle.id).exists?
                 }.from(true).to(false)
        end
      end

      context 'with at least one completed order' do
        it 'skips deletion' do
          completed_order = create(
            :order, state: 'complete',
                    distributor_id: other_enterprise.id, order_cycle_id: order_cycle.id
          )
          create(:line_item, order: completed_order, variant: variant)

          expect { service.call }.not_to change { Enterprise.where(id: enterprise.id).exists? }
          expect { service.call }
            .not_to change { OrderCycle.where(id: order_cycle.id).exists? }
        end
      end
    end

    context 'database transaction behavior' do
      let!(:product) { create(:product, supplier_id: enterprise.id) }
      let!(:variant) { product.variants.first }

      it 'wraps deletion in a transaction' do
        expect(ActiveRecord::Base).to receive(:transaction).exactly(4).times.and_call_original
        # One call for the described class
        # One call for variant#destruction
        # One call for product#destruction
        # One missed somewhere...
        service.call
      end

      context 'when an error occurs during deletion' do
        before do
          allow_any_instance_of(Spree::Variant)
            .to receive(:really_destroy!).and_raise(StandardError)
        end

        it 'rolls back all changes' do
          expect { service.call }.to raise_error(StandardError)
          expect(Enterprise.exists?(enterprise.id)).to be(true)
        end
      end
    end
  end

  describe '#check_condition_for_variant' do
    let!(:product) { create(:product, supplier_id: enterprise.id) }
    let!(:variant) { product.variants.first }

    context 'when variant has completed orders' do
      before do
        completed_order = create(:order, state: 'complete')
        create(:line_item, order: completed_order, variant: variant)
      end

      it 'raise error' do
        expect { service.__send__(:check_condition_for_variant, variant) }
          .to raise_error(Enterprises::Delete::DeletionError)
      end
    end

    context 'when variant has no completed orders' do
      before do
        cart_order = create(:order, state: 'cart')
        create(:line_item, order: cart_order, variant: variant)
      end

      it 'does not raise an error' do
        expect { service.__send__(:check_condition_for_variant, variant) }
          .not_to raise_error
      end
    end

    context 'when variant has no orders' do
      it 'does not raise an error' do
        expect { service.__send__(:check_condition_for_variant, variant) }
          .not_to raise_error
      end
    end
  end

  describe '#delete_stock_movements_for' do
    let!(:product) { create(:product, supplier_id: enterprise.id) }
    let!(:variant) { product.variants.first }
    let!(:stock_item) { Spree::StockItem.find_or_create_by!(variant: variant) }
    let!(:stock_movement) do
      sql = "INSERT INTO spree_stock_movements (stock_item_id, quantity, created_at, updated_at) " \
            "VALUES (?, ?, ?, ?)"
      ActiveRecord::Base.connection.exec_insert(
        ActiveRecord::Base.sanitize_sql_array([sql, stock_item.id, 1, Time.zone.now, Time.zone.now])
      )
    end

    it 'deletes stock movements using raw SQL' do
      Rails.logger.debug stock_movement.rows[0][0].inspect
      expect {
        service.__send__(:delete_stock_movements_for, stock_item)
      }.to change {
        sql = "SELECT 1 FROM spree_stock_movements WHERE id = ? LIMIT 1"
        ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.sanitize_sql_array([sql, stock_movement.rows[0][0]])
        ).rows.size.to_i
      }.by(-1)
    end

    it 'uses sanitized SQL to prevent injection' do
      expect(ActiveRecord::Base).to receive(:sanitize_sql_array).and_call_original
      service.__send__(:delete_stock_movements_for, stock_item)
    end
  end

  describe '#delete_variants_related_data_for' do
    let!(:product) { create(:product, supplier_id: enterprise.id) }
    let!(:variant) { product.variants.first }
    let!(:stock_item) { Spree::StockItem.find_or_create_by!(variant: variant) }

    it 'deletes stock items' do
      expect {
        service.__send__(:delete_variants_related_data_for, variant)
      }.to change { Spree::StockItem.with_deleted.count }.by(-1)
    end

    it 'deletes the variant' do
      expect {
        service.__send__(:delete_variants_related_data_for, variant)
      }.to change { Spree::Variant.with_deleted.count }.by(-1)
    end
  end
end
