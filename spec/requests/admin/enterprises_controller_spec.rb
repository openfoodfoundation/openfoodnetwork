# frozen_string_literal: true

RSpec.describe Admin::EnterprisesController do
  let(:admin) { create(:admin_user) }
  let(:enterprise) { create(:enterprise) }

  before do
    sign_in admin
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get edit_admin_enterprise_path(enterprise)
      expect(response).to have_http_status(:success)
    end

    it "redirect to the enterprises page for non-existing enterprise" do
      get edit_admin_enterprise_path(id: 'non-existing')
      expect(response).to redirect_to(admin_enterprises_path)
    end
  end

  describe 'PATCH #update' do
    let(:pdf) {
      fixture_file_upload(Rails.public_path.join("Terms-of-service.pdf"), "application/pdf")
    }
    let(:png) { fixture_file_upload("logo.png", "image/png") }
    let(:blank_error) { CGI.escapeHTML("can't be blank") }

    context "when the enterprise already has terms and conditions" do
      let(:saved_file_link) { "Terms-of-service.pdf uploaded on" }

      before { enterprise.update!(terms_and_conditions: pdf) }

      it "shows the error and keeps the saved file when a non-PDF is uploaded" do
        patch admin_enterprise_path(enterprise), params: {
          enterprise: { terms_and_conditions: png }
        }

        expect(response.body).to include "Only PDFs are allowed"
        expect(response.body).to include saved_file_link
        expect(enterprise.reload.terms_and_conditions.filename).to eq "Terms-of-service.pdf"
      end

      it "keeps showing the saved file when removing it fails" do
        patch admin_enterprise_path(enterprise), params: {
          enterprise: { name: "", remove_terms_and_conditions: "1" }
        }

        expect(response.body).to include blank_error
        expect(response.body).to include saved_file_link
        expect(enterprise.reload.terms_and_conditions).to be_attached
      end
    end

    it "shows the error when another field is invalid and a PDF is uploaded" do
      patch admin_enterprise_path(enterprise), params: {
        enterprise: { name: "", terms_and_conditions: pdf }
      }

      expect(response.body).to include blank_error
      expect(enterprise.reload.terms_and_conditions).not_to be_attached
    end

    it "doesn't raise an alert for an unsaved logo when another field is invalid" do
      expect(Alert).not_to receive(:raise)

      patch admin_enterprise_path(enterprise), params: {
        enterprise: { name: "", logo: png }
      }

      expect(response.body).to include blank_error
    end
  end

  describe 'GET #index' do
    it "does not raise when q is submitted in array notation instead of a hash" do
      expect {
        get admin_enterprises_path(q: ["foo", "bar"])
      }.not_to raise_error

      expect(response).to have_http_status(:success)
    end
  end
end
