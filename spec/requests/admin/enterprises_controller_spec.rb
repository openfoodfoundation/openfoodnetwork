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

  describe 'GET #index' do
    it "does not raise when q is submitted in array notation instead of a hash" do
      expect {
        get admin_enterprises_path(q: ["foo", "bar"])
      }.not_to raise_error

      expect(response).to have_http_status(:success)
    end
  end
end
