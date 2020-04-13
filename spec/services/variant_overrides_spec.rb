require 'spec_helper'

describe VariantOverrides do
  subject(:variant_overrides) do
    described_class.new(
      line_items: order.line_items,
      distributor_ids: [distributor.id],
    )
  end

  let(:distributor) { create(:distributor_enterprise) }
  let(:order) do
    create(:completed_order_with_totals, line_items_count: 1,
            distributor: distributor)
  end
  let(:line_item) { order.line_items.first }
  let!(:variant_override) do
    create(
      :variant_override,
      hub: vo_distributor,
      variant: vo_variant,
    )
  end

  describe '#indexed' do
    let(:result) { variant_overrides.indexed }

    context 'when variant overrides exist for variants of specified line items' do
      let(:vo_variant) { line_item.variant }

      context 'when variant overrides apply to one of the specified distributors' do
        let(:vo_distributor) { distributor }

        it 'they are included in the mapping' do
          expect(result).to eq(
            distributor.id => { line_item.variant => variant_override }
          )
        end
      end

      context 'when variant overrides don\'t apply to one of the specified distributors' do
        let(:vo_distributor) { create(:distributor_enterprise) }

        it 'they are not included in the mapping' do
          expect(result).to eq({})
        end
      end
    end

    context 'when variant overrides exist for other variants' do
      let(:vo_variant) { create(:variant) }

      context 'when variant overrides apply to one of the specified distributors' do
        let(:vo_distributor) { distributor }

        it 'they are not included in the mapping' do
          expect(result).to eq({})
        end
      end

      context 'when variant overrides don\'t apply to one of the specified distributors' do
        let(:vo_distributor) { create(:distributor_enterprise) }

        it 'they are not included in the mapping' do
          expect(result).to eq({})
        end
      end
    end
  end
end
