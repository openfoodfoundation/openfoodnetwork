require 'spec_helper'

describe ProductImport::InventoryResetStrategy do
  let(:inventory_reset) { described_class.new(excluded_items_ids) }

  describe '#reset' do
    let(:supplier_ids) { enterprise.id }
    let(:enterprise) { variant.product.supplier }
    let(:variant) { create(:variant) }

    let!(:variant_override) do
      create(
        :variant_override,
        count_on_hand: 10,
        hub: enterprise,
        variant: variant
      )
    end

    context 'when there are excluded_items_ids' do
      let(:excluded_items_ids) { [variant_override.id] }

      context 'and supplier_ids is []' do
        let(:supplier_ids) { [] }
        let(:relation) do
          instance_double(ActiveRecord::Relation, update_all: true)
        end

        before { allow(VariantOverride).to receive(:where) { relation } }

        it 'does not update any DB record' do
          inventory_reset.reset(supplier_ids)
          expect(relation).not_to have_received(:update_all)
        end
      end

      context 'and supplier_ids is nil' do
        let(:supplier_ids) { nil }
        let(:relation) do
          instance_double(ActiveRecord::Relation, update_all: true)
        end

        before { allow(VariantOverride).to receive(:where) { relation } }

        it 'does not update any DB record' do
          inventory_reset.reset(supplier_ids)
          expect(relation).not_to have_received(:update_all)
        end
      end

      context 'and supplier_ids is set' do
        it 'does not update the count_on_hand of the excluded items' do
          inventory_reset.reset(supplier_ids)
          expect(variant_override.reload.count_on_hand).to eq(10)
        end

        it 'updates the count_on_hand of the non-excluded items' do
          non_excluded_variant_override = create(
            :variant_override,
            count_on_hand: 3,
            hub: enterprise,
            variant: variant
          )
          inventory_reset.reset(supplier_ids)
          expect(non_excluded_variant_override.reload.count_on_hand).to eq(0)
        end
      end
    end

    context 'when there are no excluded_items_ids' do
      let(:excluded_items_ids) { [] }

      context 'and supplier_ids is []' do
        let(:supplier_ids) { [] }
        let(:relation) do
          instance_double(ActiveRecord::Relation, update_all: true)
        end

        before { allow(VariantOverride).to receive(:where) { relation } }

        it 'does not update any DB record' do
          inventory_reset.reset(supplier_ids)
          expect(relation).not_to have_received(:update_all)
        end
      end

      context 'and supplier_ids is nil' do
        let(:supplier_ids) { nil }
        let(:relation) do
          instance_double(ActiveRecord::Relation, update_all: true)
        end

        before { allow(VariantOverride).to receive(:where) { relation } }

        it 'does not update any DB record' do
          inventory_reset.reset(supplier_ids)
          expect(relation).not_to have_received(:update_all)
        end
      end

      context 'and supplier_ids is set' do
        it 'sets all count_on_hand to 0' do
          inventory_reset.reset(supplier_ids)
          expect(variant_override.reload.count_on_hand).to eq(0)
        end
      end
    end

    context 'when excluded_items_ids is nil' do
      let(:excluded_items_ids) { nil }

      context 'and supplier_ids is []' do
        let(:supplier_ids) { [] }
        let(:relation) do
          instance_double(ActiveRecord::Relation, update_all: true)
        end

        before { allow(VariantOverride).to receive(:where) { relation } }

        it 'does not update any DB record' do
          inventory_reset.reset(supplier_ids)
          expect(relation).not_to have_received(:update_all)
        end
      end

      context 'and supplier_ids is nil' do
        let(:supplier_ids) { nil }
        let(:relation) do
          instance_double(ActiveRecord::Relation, update_all: true)
        end

        before { allow(VariantOverride).to receive(:where) { relation } }

        it 'does not update any DB record' do
          inventory_reset.reset(supplier_ids)
          expect(relation).not_to have_received(:update_all)
        end
      end

      context 'and supplier_ids is set' do
        it 'sets all count_on_hand to 0' do
          inventory_reset.reset(supplier_ids)
          expect(variant_override.reload.count_on_hand).to eq(0)
        end
      end
    end
  end
end
