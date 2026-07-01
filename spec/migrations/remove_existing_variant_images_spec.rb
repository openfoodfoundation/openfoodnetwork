# frozen_string_literal: true

require_relative '../../db/migrate/20260701201850_remove_existing_variant_images'

RSpec.describe RemoveExistingVariantImages, type: :migration do
  include FileHelper

  subject(:migration) { described_class.new }

  let(:attachment) { white_logo_file }

  describe '#up' do
    it "removes all variant images and purges their blobs" do
      variant = create(:variant)
      variant_image = Spree::Image.create!(attachment:, viewable: variant)
      blob_id = variant_image.attachment.blob_id
      attachment_id = variant_image.attachment.id
      product_image = Spree::Image.create!(attachment:, viewable: create(:product))

      expect { migration.up }
        .to change { Spree::Image.where(viewable_type: 'Spree::Variant').count }
        .from(1).to(0)

      expect(Spree::Image.where(viewable_type: 'Spree::Product').count).to eq 1
      expect(product_image.reload.attachment).to be_present
      expect(ActiveStorage::Attachment.find_by(id: attachment_id)).to be_nil
      expect(ActiveStorage::Blob.find_by(id: blob_id)).to be_nil
    end

    it "does not remove product images" do
      product = create(:product)
      Spree::Image.create!(attachment:, viewable_id: product.id,
                           viewable_type: 'Spree::Product')
      Spree::Image.create!(attachment:, viewable_id: product.id,
                           viewable_type: 'Spree::Product')

      expect { migration.up }.not_to change {
        Spree::Image.where(viewable_type: 'Spree::Product').count
      }
    end
  end
end
