# frozen_string_literal: true

require "spec_helper"

describe Api::Admin::EnterpriseSerializer do
  let(:enterprise) { create(:distributor_enterprise) }
  it "serializes an enterprise" do
    serializer = Api::Admin::EnterpriseSerializer.new enterprise
    expect(serializer.to_json).to match enterprise.name
  end

  context "for logo" do
    let(:enterprise) { create(:distributor_enterprise, logo: image) }

    context "when there is a logo" do
      let(:image) do
        image_path = File.open(Rails.root.join("app", "webpacker", "images", "logo-black.png"))
        Rack::Test::UploadedFile.new(image_path, "image/png")
      end

      it "includes URLs of image versions" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:logo]).to_not be_blank
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
        image_path = File.open(Rails.root.join("app", "webpacker", "images", "logo-black.png"))
        Rack::Test::UploadedFile.new(image_path, "image/png")
      end

      it "includes URLs of image versions" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:promo_image]).to_not be_blank
        expect(serializer.as_json[:promo_image][:medium]).to match(/logo-black.jpg/)
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
end
