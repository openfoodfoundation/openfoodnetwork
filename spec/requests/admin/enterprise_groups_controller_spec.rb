# frozen_string_literal: true

RSpec.describe Admin::EnterpriseGroupsController do
  let(:admin) { create(:admin_user) }
  let(:group) { create(:enterprise_group) }
  let(:png) { fixture_file_upload("logo.png", "image/png") }
  let(:pdf) {
    fixture_file_upload(Rails.public_path.join("Terms-of-service.pdf"), "application/pdf")
  }

  before do
    sign_in admin
  end

  def field_error(field)
    /field_with_errors"><label[^>]*for="enterprise_group_#{field}"/
  end

  describe "PATCH #update" do
    it "shows the error when another field is invalid and a logo is uploaded" do
      patch admin_enterprise_group_path(group), params: {
        enterprise_group: { name: "", logo: png }
      }

      expect(response).to render_template :edit
      expect(response.body).to match field_error(:name)
      expect(group.reload.logo).not_to be_attached
    end

    it "shows the error when another field is invalid and a promo image is uploaded" do
      patch admin_enterprise_group_path(group), params: {
        enterprise_group: { name: "", promo_image: png }
      }

      expect(response).to render_template :edit
      expect(response.body).to match field_error(:name)
      expect(group.reload.promo_image).not_to be_attached
    end

    it "shows the error when an unprocessable image is uploaded" do
      corrupt = Rack::Test::UploadedFile.new(
        StringIO.new("not an image"), "image/png", original_filename: "corrupt.png"
      )

      patch admin_enterprise_group_path(group), params: {
        enterprise_group: { logo: corrupt }
      }

      expect(response).to render_template :edit
      expect(response.body).to match field_error(:logo)
      expect(group.reload.logo).not_to be_attached
    end

    context "when the group already has images" do
      before { group.update!(logo: png, promo_image: png) }

      it "shows the error and keeps the saved images when non-images are uploaded" do
        patch admin_enterprise_group_path(group), params: {
          enterprise_group: { logo: pdf, promo_image: pdf }
        }

        group.reload
        expect(response).to render_template :edit
        expect(response.body).to match field_error(:logo)
        expect(response.body).to match field_error(:promo_image)
        expect(response.body).to include rails_blob_path(group.logo)
        expect(response.body).to include rails_blob_path(group.promo_image)
        expect(group.logo.filename).to eq "logo.png"
        expect(group.promo_image.filename).to eq "logo.png"
      end
    end
  end

  describe "POST #create" do
    it "shows the error when another field is invalid and a logo is uploaded" do
      expect {
        post admin_enterprise_groups_path, params: {
          enterprise_group: { name: "", logo: png }
        }
      }.not_to change { EnterpriseGroup.count }

      expect(response).to render_template :new
      expect(response.body).to match field_error(:name)
    end
  end
end
