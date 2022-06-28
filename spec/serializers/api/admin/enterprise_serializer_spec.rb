# frozen_string_literal: true

require "spec_helper"

describe Api::Admin::EnterpriseSerializer do
  include FileHelper

  let(:enterprise) { create(:distributor_enterprise) }
  it "serializes an enterprise" do
    serializer = Api::Admin::EnterpriseSerializer.new enterprise
    expect(serializer.to_json).to match enterprise.name
  end

  context "for logo" do
    let(:enterprise) { create(:distributor_enterprise, logo: image) }

    context "when there is a logo" do
      let(:image) do
        black_logo_file
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
        black_logo_file
      end

      it "includes URLs of image versions" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:promo_image]).to_not be_blank
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

  context "for small farmer recognition document" do
    let(:enterprise) { create(:distributor_enterprise, small_farmer_recognition_document: image) }

    context "when there is a document" do
      let(:image) do
        black_logo_file
      end

      it "includes information about the document" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:small_farmer_recognition_document]).to_not be_blank
        expect(serializer.as_json[:small_farmer_recognition_document_file_name])
          .to eq('logo-black.png')
      end
    end

    context "when there is no document" do
      let(:image) { nil }

      it "does not include information about the document" do
        serializer = Api::Admin::EnterpriseSerializer.new(enterprise)
        expect(serializer.as_json[:small_farmer_recognition_document]).to be_nil
      end
    end
  end
end
