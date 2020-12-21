# frozen_string_literal: true

require 'spec_helper'

describe ProductImport::InventoryResetStrategy do
  let(:inventory_reset) { described_class.new(excluded_items_ids) }

  describe '#reset' do
    context 'when there are excluded_items_ids' do
      let(:enterprise) { variant.product.supplier }
      let(:variant) { build_stubbed(:variant) }
      let!(:variant_override) do
        build_stubbed(
          :variant_override,
          count_on_hand: 10,
          hub: enterprise,
          variant: variant
        )
      end
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
        let(:supplier_ids) { enterprise.id }
        let(:variant) { create(:variant) }
        let!(:variant_override_with_count_on_hand) do
          create(
            :variant_override,
            count_on_hand: 10,
            hub: enterprise,
            variant: variant
          )
        end
        let!(:variant_override_on_demand) do
          create(
            :variant_override,
            count_on_hand: nil,
            on_demand: true,
            hub: enterprise,
            variant: variant
          )
        end
        let(:excluded_items_ids) do
          [variant_override_with_count_on_hand.id, variant_override_on_demand.id]
        end

        it 'does not update the count_on_hand or on_demand setting of the excluded items' do
          inventory_reset.reset(supplier_ids)
          expect(variant_override_with_count_on_hand.reload.count_on_hand).to eq(10)
          expect(variant_override_on_demand.reload.on_demand).to eq(true)
        end

        it 'updates the count_on_hand or on_demand setting of the non-excluded items' do
          non_excluded_variant_override_with_count_on_hand = create(
            :variant_override,
            count_on_hand: 3,
            hub: enterprise,
            variant: variant
          )
          non_excluded_variant_override_on_demand = create(
            :variant_override,
            count_on_hand: nil,
            on_demand: true,
            hub: enterprise,
            variant: variant
          )
          inventory_reset.reset(supplier_ids)
          expect(non_excluded_variant_override_with_count_on_hand.reload.count_on_hand).to eq(0)
          expect(non_excluded_variant_override_on_demand.reload.on_demand).to eq(false)
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
        let(:supplier_ids) { enterprise.id }
        let(:enterprise) { variant.product.supplier }
        let(:variant) { create(:variant) }

        context "and variant overrides with count on hand" do
          let!(:variant_override) do
            create(
              :variant_override,
              count_on_hand: 10,
              hub: enterprise,
              variant: variant
            )
          end

          it 'sets their count_on_hand to 0' do
            inventory_reset.reset(supplier_ids)
            expect(variant_override.reload.count_on_hand).to eq(0)
          end
        end

        context 'and variant overides on demand' do
          let!(:variant_override) do
            create(
              :variant_override,
              count_on_hand: nil,
              on_demand: true,
              hub: enterprise,
              variant: variant
            )
          end

          it 'turns off their on_demand setting' do
            inventory_reset.reset(supplier_ids)
            expect(variant_override.reload.on_demand).to eq(false)
          end
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
        let(:supplier_ids) { enterprise.id }
        let(:enterprise) { variant.product.supplier }
        let(:variant) { create(:variant) }

        context "and variant overrides with count on hand" do
          let!(:variant_override) do
            create(
              :variant_override,
              count_on_hand: 10,
              hub: enterprise,
              variant: variant
            )
          end

          it 'sets their count_on_hand to 0' do
            inventory_reset.reset(supplier_ids)
            expect(variant_override.reload.count_on_hand).to eq(0)
          end
        end

        context "and variant overrides on demand" do
          let!(:variant_override) do
            create(
              :variant_override,
              count_on_hand: nil,
              on_demand: true,
              hub: enterprise,
              variant: variant
            )
          end

          it 'turns off their on_demand setting' do
            inventory_reset.reset(supplier_ids)
            expect(variant_override.reload.on_demand).to eq(false)
          end
        end
      end
    end
  end
end
