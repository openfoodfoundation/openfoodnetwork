# frozen_string_literal: true

require 'spec_helper'

describe Admin::TermsOfServiceFilesController, type: :controller do
  context "a non-admin user" do
    let(:user) { create(:user) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    it "does not allow deletion" do
      post :destroy
      expect(TermsOfServiceFile).to_not receive(:current)
    end

    it "does not allow creation" do
      post :create
      expect(TermsOfServiceFile).to_not receive(:create!)
    end
  end

  context "an admin user" do
    let(:user) { create(:admin_user) }

    before do
      allow(controller).to receive(:spree_current_user) { user }
    end

    describe "trying to create terms of service without a file" do
      it "redirects and show an error" do
        post :create, params: {}
        expect(response).to redirect_to admin_terms_of_service_files_path
        expect(flash[:error]).to eq 'Please select a file first.'
      end
    end

    describe "deleting a TOS file" do
      let(:tos_file) { double(:tos_file) }

      before do
        allow(TermsOfServiceFile).to receive(:current) { tos_file }
        allow(tos_file).to receive(:destroy!)
      end

      it "deletes the file" do
        expect(tos_file).to receive(:destroy!)
        post :destroy
      end
    end

    describe "creating a TOS file" do
      it "creates the file" do
        expect(TermsOfServiceFile).to receive(:create!)
        post :create, params: { terms_of_service_file: double(:attachment) }
      end
    end
  end
end
