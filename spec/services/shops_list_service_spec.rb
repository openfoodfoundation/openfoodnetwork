# frozen_string_literal: true

RSpec.describe ShopsListService do
  subject { described_class.new }
  before do
    enterprises = create_list :enterprise, 3, :with_logo_image, :with_promo_image
    distributors = create_list :distributor_enterprise, 3,
                               :with_logo_image,
                               :with_promo_image,
                               with_payment_and_shipping: true
    create :distributor_order_cycle, distributors: [distributors[0]], suppliers: [enterprises[0]]
  end

  let(:shop) { shops.first }

  describe "#open_shops" do
    let(:shops) { subject.open_shops }

    it "preloads promo images" do
      expect(shop.association(:promo_image_attachment).loaded?).to be true
      expect(shop.promo_image.association(:blob).loaded?).to be true
    end

    it "preloads logos" do
      expect(shop.association(:logo_attachment).loaded?).to be true
      expect(shop.logo.association(:blob).loaded?).to be true
    end

    it "only fetches enterprises with an active order cycle" do
      open_enterprise_ids = Enterprise.distributors_with_active_order_cycles.pluck(:id).to_set
      expect(open_enterprise_ids).not_to be_empty
      expect(shops.pluck(:id)).to all be_in open_enterprise_ids
    end
  end

  describe "#closed_shops" do
    let(:shops) { subject.closed_shops }

    it "preloads promo images" do
      expect(shop.association(:promo_image_attachment).loaded?).to be true
      expect(shop.promo_image.association(:blob).loaded?).to be true
    end

    it "preloads logos" do
      expect(shop.association(:logo_attachment).loaded?).to be true
      expect(shop.logo.association(:blob).loaded?).to be true
    end

    it "fetches enterprises without active order cycles" do
      open_enterprise_ids = Enterprise.distributors_with_active_order_cycles.pluck(:id).to_set
      expect(open_enterprise_ids).not_to be_empty

      shops.pluck(:id).each do |shop_id|
        expect(shop_id).not_to be_in open_enterprise_ids
      end
    end
  end
end
