# frozen_string_literal: true

require_relative '../../db/migrate/20260602222924_ensure_single_product_image'

RSpec.describe EnsureSingleProductImage, type: :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:product) { create(:product) }

    it 'keeps the first image and removes additional images for a product' do
      first_image = described_class::SpreeImage.create!(
        viewable_type: 'Spree::Product',
        viewable_id: product.id,
        type: 'Spree::Image'
      )
      second_image = described_class::SpreeImage.create!(
        viewable_type: 'Spree::Product',
        viewable_id: product.id,
        type: 'Spree::Image'
      )

      expect do
        migration.up
      end.to change {
        described_class::SpreeImage.where(
          viewable_type: 'Spree::Product', viewable_id: product.id
        ).count
      }.from(2).to(1)

      remaining_ids = described_class::SpreeImage.where(
        viewable_type: 'Spree::Product',
        viewable_id: product.id
      ).pluck(:id)

      expect(remaining_ids).to contain_exactly(first_image.id)
      expect(remaining_ids).not_to include(second_image.id)
    end

    it 'does not remove an image when a product already has a single image' do
      image = described_class::SpreeImage.create!(
        viewable_type: 'Spree::Product',
        viewable_id: product.id,
        type: 'Spree::Image'
      )

      expect do
        migration.up
      end.not_to change {
        described_class::SpreeImage.where(
          viewable_type: 'Spree::Product', viewable_id: product.id
        ).count
      }

      expect(described_class::SpreeImage.exists?(image.id)).to be(true)
    end

    it 'does not remove assets for non-product viewables' do
      variant = create(:variant)
      described_class::SpreeImage.create!(
        viewable_type: 'Spree::Variant',
        viewable_id: variant.id,
        type: 'Spree::Image'
      )
      described_class::SpreeImage.create!(
        viewable_type: 'Spree::Variant',
        viewable_id: variant.id,
        type: 'Spree::Image'
      )

      expect do
        migration.up
      end.not_to change {
        described_class::SpreeImage.where(
          viewable_type: 'Spree::Variant', viewable_id: variant.id
        ).count
      }
    end
  end
end
