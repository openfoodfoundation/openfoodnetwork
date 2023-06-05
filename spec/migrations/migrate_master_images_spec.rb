# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20230603181837_migrate_master_image_to_product'

describe MigrateMasterImageToProduct do
  subject { MigrateMasterImageToProduct.new }

  let!(:product1) { create(:product) }
  let!(:master1) { create(:variant, product: product1, is_master: true) }
  let!(:image1) { create(:asset, viewable: master1, position: 1) }
  let!(:image2) { create(:asset, viewable: master1, position: 2) }

  let!(:product2) { create(:product) }
  let!(:master2) { create(:variant, product: product2, is_master: true) }
  let!(:image3) { create(:asset, viewable: master2, position: 2) }
  let!(:image4) { create(:asset, viewable: master2, position: 3) }
  let!(:image5) { create(:asset, viewable: master2, position: 4) }

  describe "#renumber_first_image" do
    it "updates the first image to position 1 if it's not already 1" do
      subject.renumber_first_image

      expect(image1.reload.position).to eq 1
      expect(image3.reload.position).to eq 1
    end
  end

  describe "#migrate_master_images" do
    before { image3.update_columns(position: 1) }

    it "migrates the master variant image to the product" do
      subject.migrate_master_images

      expect(product1.reload.image.id).to eq image1.id
      expect(product2.reload.image.id).to eq image3.id
    end
  end
end
