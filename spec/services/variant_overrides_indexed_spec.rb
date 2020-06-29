# frozen_string_literal: true

require 'spec_helper'

describe VariantOverridesIndexed do
  subject(:variant_overrides) { described_class.new([variant.id], [distributor.id]) }

  let(:distributor) { create(:distributor_enterprise) }
  let(:variant) { create(:variant) }
  let!(:variant_override) do
    create(
      :variant_override,
      hub: vo_distributor,
      variant: vo_variant,
    )
  end

  describe '#indexed' do
    let(:result) { variant_overrides.indexed }

    context 'when variant overrides exist for variants of specified variants' do
      let(:vo_variant) { variant }

      context 'when variant overrides apply to one of the specified distributors' do
        let(:vo_distributor) { distributor }

        it 'they are included in the mapping' do
          expect(result).to eq(
            distributor.id => { variant => variant_override }
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
