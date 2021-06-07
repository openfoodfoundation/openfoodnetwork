# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::InvoicesController, type: :controller do
  let(:order) { create(:order_with_totals_and_distribution) }
  let(:enterprise_user) { create(:user) }
  let!(:enterprise) { create(:enterprise, owner: enterprise_user) }

  before do
    allow(controller).to receive(:spree_current_user) { enterprise_user }
  end

  describe "#create" do
    it "enqueues a job to create a bulk invoice and returns the filename" do
      expect do
        spree_post :create, order_ids: [order.id]
      end.to enqueue_job BulkInvoiceJob
    end
  end

  describe "#poll" do
    let(:invoice_id) { '479186263' }

    context "when the file is available" do
      it "returns true" do
        allow(File).to receive(:exist?)
        allow(File).to receive(:exist?).with("tmp/invoices/#{invoice_id}.pdf").and_return(true)

        spree_get :poll, invoice_id: invoice_id

        expect(response.body).to eq({ created: true }.to_json)
        expect(response.status).to eq 200
      end
    end

    context "when the file is not available" do
      it "returns false" do
        spree_get :poll, invoice_id: invoice_id

        expect(response.body).to eq({ created: false }.to_json)
        expect(response.status).to eq 422
      end
    end
  end
end
