# frozen_string_literal: true

require_relative '../../db/migrate/20260611223814_ensure_single_product_image'

RSpec.describe EnsureSingleProductImage, type: :migration do
  let(:migration) { described_class.new }
  let(:attachment) { Rack::Test::UploadedFile.new(Rails.root.join('app/webpacker/images/logo-white.png'), "image/png") }

  describe '#up' do
    let(:product) { create(:product) }

    it 'keeps the first image and soft deletes additional images for a product' do
      first_image = Spree::Image.create(attachment:,
                                        viewable_id: product.id,
                                        viewable_type: 'Spree::Product')

      second_image = Spree::Image.create(attachment:,
                                         viewable_id: product.id,
                                         viewable_type: 'Spree::Product')

      expect do
        migration.up
      end.to change {
        Spree::Image.where(
          viewable_type: 'Spree::Product', viewable_id: product.id
        ).count
      }.from(2).to(1)

      remaining_ids = Spree::Image.where(
        viewable_type: 'Spree::Product',
        viewable_id: product.id
      ).pluck(:id)

      expect(remaining_ids).to contain_exactly(first_image.id)
      expect(remaining_ids).not_to include(second_image.id)

      # Verify second image is soft deleted, not hard deleted
      soft_deleted_image = Spree::Image.unscoped.find(second_image.id)
      expect(soft_deleted_image.deleted_at).not_to be_nil
      expect(soft_deleted_image.attachment_blob).not_to be_nil
    end

    it 'does not remove an image when a product already has a single image' do
      image = Spree::Image.create(attachment:,
                                  viewable_id: product.id,
                                  viewable_type: 'Spree::Product')

      expect do
        migration.up
      end.not_to change {
        Spree::Image.where(
          viewable_type: 'Spree::Product', viewable_id: product.id
        ).count
      }

      expect(Spree::Image.exists?(image.id)).to be(true)
    end

    it 'does not remove assets for non-product viewables' do
      variant = create(:variant)
      first_variant_image = Spree::Image.create!(attachment:,
                                                 viewable_id: variant.id,
                                                 viewable_type: 'Spree::Variant')
      second_variant_image = Spree::Image.create!(attachment:,
                                                  viewable_id: variant.id,
                                                  viewable_type: 'Spree::Variant')

      expect do
        migration.up
      end.not_to change {
        Spree::Image.where(
          viewable_type: 'Spree::Variant', viewable_id: variant.id
        ).count
      }

      # Verify both variant images are not deleted
      expect(Spree::Image.unscoped.find(first_variant_image.id).deleted_at).to be_nil
      expect(Spree::Image.unscoped.find(second_variant_image.id).deleted_at).to be_nil
    end
  end
end
