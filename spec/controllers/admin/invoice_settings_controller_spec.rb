# frozen_string_literal: true

require 'spec_helper'

describe Admin::InvoiceSettingsController, type: :controller do
  describe "#update" do
    let(:params) {
      {
        preferences: {
          enable_invoices?: 0,
          invoice_style2?: 1,
        }
      }
    }

    before do
      allow(controller).to receive(:spree_current_user) { create(:admin_user) }
    end

    it "disables invoices" do
      expect {
        post :update, params: params
      }.to change {
        Spree::Config[:enable_invoices?]
      }.to(false)
    end

    it "changes the invoice style" do
      expect {
        post :update, params: params
      }.to change {
        Spree::Config[:invoice_style2?]
      }.to(true)
    end
  end
end
