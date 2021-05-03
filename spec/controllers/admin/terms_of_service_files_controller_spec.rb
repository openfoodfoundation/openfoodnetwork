# frozen_string_literal: true

require 'spec_helper'

describe Admin::TermsOfServiceFilesController, type: :controller do
  let(:user) { create(:admin_user) }

  before do
    allow(controller).to receive(:spree_current_user) { user }
  end

  describe "trying to create terms of service without a file" do
    it "redirects and show an error" do
      post :create, params: {}
      expect(response).to redirect_to admin_terms_of_service_files_path
      expect(flash[:error]).to eq I18n.t(".admin.terms_of_service_files.create.select_file")
    end
  end
end
