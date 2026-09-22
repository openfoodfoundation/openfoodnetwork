# frozen_string_literal: true

require_relative '../../db/migrate/20260611223814_ensure_single_product_image'

RSpec.describe EnsureSingleProductImage, type: :migration do
  let(:migration) { described_class.new }
  let(:attachment) {
    Rack::Test::UploadedFile.new(
      Rails.root.join('app/webpacker/images/logo-white.png'), "image/png"
    )
  }

  # RemoveDeletedAtFromAssets drops this column, and Spree::Image no longer uses
  # acts_as_paranoid, so the current schema/model has neither the column nor a
  # default scope. Recreate the column for the duration of the example to exercise
  # this migration against the schema it was written for. Assertions read deleted_at
  # directly rather than relying on a soft-delete default scope, which no longer exists.
  around do |example|
    connection = ActiveRecord::Base.connection
    connection.add_column(:spree_assets, :deleted_at, :datetime)
    described_class::SpreeImage.reset_column_information
    Spree::Asset.reset_column_information

    example.run
  ensure
    connection.remove_column(:spree_assets, :deleted_at)
    described_class::SpreeImage.reset_column_information
    Spree::Asset.reset_column_information
  end

  describe '#up' do
    let(:product) { create(:product) }

    it 'keeps the first image and soft deletes additional images for a product' do
      first_image = Spree::Image.create!(attachment:,
                                         viewable_id: product.id,
                                         viewable_type: 'Spree::Product')
      second_image = Spree::Image.create!(attachment:,
                                          viewable_id: product.id,
                                          viewable_type: 'Spree::Product')

      migration.up

      # Both rows still exist (no default scope hides them), but exactly one is
      # marked deleted: the preserved image stays live, the extra is soft-deleted.
      expect(deleted_at_for(first_image)).to be_nil
      expect(deleted_at_for(second_image)).not_to be_nil

      # The soft-deleted row keeps its attachment (the purge migration removes it later).
      expect(second_image.reload.attachment_blob).not_to be_nil
    end

    it 'does not remove an image when a product already has a single image' do
      image = Spree::Image.create!(attachment:,
                                   viewable_id: product.id,
                                   viewable_type: 'Spree::Product')

      migration.up

      expect(deleted_at_for(image)).to be_nil
    end

    it 'does not remove assets for non-product viewables' do
      variant = create(:variant)
      first_variant_image = Spree::Image.create!(attachment:,
                                                 viewable_id: variant.id,
                                                 viewable_type: 'Spree::Variant')
      second_variant_image = Spree::Image.create!(attachment:,
                                                  viewable_id: variant.id,
                                                  viewable_type: 'Spree::Variant')

      migration.up

      expect(deleted_at_for(first_variant_image)).to be_nil
      expect(deleted_at_for(second_variant_image)).to be_nil
    end
  end

  # deleted_at isn't on the current Spree::Image model, so read the column straight
  # from the table via the migration's own AR class.
  def deleted_at_for(image)
    described_class::SpreeImage.where(id: image.id).pick(:deleted_at)
  end
end
