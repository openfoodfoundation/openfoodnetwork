# frozen_string_literal: true

RSpec.describe Api::Admin::EnterpriseSerializer do
  include FileHelper

  let(:enterprise) { create(:distributor_enterprise, external_billing_id: 'INV123456') }
  it "serializes an enterprise" do
    serializer = Api::Admin::EnterpriseSerializer.new enterprise
    expect(serializer.to_json).to match enterprise.name
    expect(serializer.as_json[:external_billing_id]).to eq('INV123456')
  end

  context "for logo" do
    let(:enterprise) { create(:distributor_enterprise, logo: image) }

    context "when there is a logo" do
      let(:image) do
        black_logo_file
      end

      it "includes URLs of image versions" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:logo]).not_to be_blank
        expect(serializer.as_json[:logo][:medium]).to match(/logo-black.png/)
      end
    end

    context "when there is no logo" do
      let(:image) { nil }

      it "includes URLs of image versions" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:logo]).to be_blank
      end
    end
  end

  context "for promo image" do
    let(:enterprise) { create(:distributor_enterprise, promo_image: image) }

    context "when there is a promo image" do
      let(:image) do
        black_logo_file
      end

      it "includes URLs of image versions" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:promo_image]).not_to be_blank
        expect(serializer.as_json[:promo_image][:medium]).to match(/logo-black\.png$/)
      end
    end

    context "when there is no promo image" do
      let(:image) { nil }

      it "includes URLs of image versions" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:promo_image]).to be_nil
      end
    end
  end

  context "for white label logo" do
    let(:enterprise) { create(:distributor_enterprise, white_label_logo: black_logo_file) }

    context "when there is a white label logo" do
      it "includes URLs of image versions" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:white_label_logo]).to be_present
        expect(serializer.as_json[:white_label_logo][:default]).to match(/logo-black\.png$/)
        expect(serializer.as_json[:white_label_logo][:mobile]).to match(/logo-black\.png$/)
      end
    end
  end
end
