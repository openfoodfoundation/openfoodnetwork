# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20260827000000_backfill_blank_captions_on_spree_assets'

RSpec.describe BackfillBlankCaptionsOnSpreeAssets do
  subject { described_class.new }

  let(:product) { create(:product_with_image) }
  let!(:image) { product.image }

  describe '#up' do
    it "backfills a never-set caption with an empty string" do
      subject.up

      expect(image.reload.caption).to eq ""
    end

    it "leaves an entered caption untouched" do
      image.update_columns(caption: "Fresh asparagus")

      subject.up

      expect(image.reload.caption).to eq "Fresh asparagus"
    end

    it "leaves an already blank caption blank" do
      image.update_columns(caption: "")

      subject.up

      expect(image.reload.caption).to eq ""
    end

    it "backfills every asset with a nil caption" do
      _second_image = create(:product_with_image)

      expect { subject.up }
        .to change { Spree::Asset.unscoped.where(caption: nil).count }.to(0)
    end
  end

  describe '#down' do
    it "is irreversible, since the original empty string captions can't be told apart" do
      expect { subject.down }.to raise_error ActiveRecord::IrreversibleMigration
    end
  end
end
