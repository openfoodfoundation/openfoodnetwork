# frozen_string_literal: true

require "spec_helper"

RSpec.describe ShopsListService do
  subject { described_class.new }
  before do
    create_list :enterprise, 3, :with_logo_image, :with_promo_image
    create_list :distributor_enterprise, 3,
                :with_logo_image,
                :with_promo_image,
                with_payment_and_shipping: true
  end

  let(:shop) { subject.open_shops.first }

  describe "#open_shops" do
    it "preloads promo images" do
      expect(shop.association(:promo_image_attachment).loaded?).to be true
      expect(shop.promo_image.association(:blob).loaded?).to be true
    end

    it "preloads logos" do
      expect(shop.association(:logo_attachment).loaded?).to be true
      expect(shop.logo.association(:blob).loaded?).to be true
    end
  end

  describe "#closed_shops" do
    let(:shop) { subject.closed_shops.first }

    it "preloads promo images" do
      expect(shop.association(:promo_image_attachment).loaded?).to be true
      expect(shop.promo_image.association(:blob).loaded?).to be true
    end

    it "preloads logos" do
      expect(shop.association(:logo_attachment).loaded?).to be true
      expect(shop.logo.association(:blob).loaded?).to be true
    end
  end
end
