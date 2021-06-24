# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Admin
    describe TaxRatesController, type: :controller do
      include AuthenticationHelper

      let!(:default_tax_zone) { create(:zone, default_tax: true) }
      let!(:tax_rate) {
        create(:tax_rate, name: "Original Rate", amount: 0.1, included_in_price: false,
                          calculator: build(:calculator), zone: default_tax_zone)
      }

      describe "#update" do
        before { controller_login_as_admin }

        context "when the tax rate has associated adjustments" do
          let!(:adjustment) { create(:adjustment, originator: tax_rate) }

          context "when the amount and included flag are not changed" do
            let(:params) {
              { name: "Updated Rate", amount: "0.1", included_in_price: "0" }
            }

            it "updates the record" do
              expect {
                spree_put :update, id: tax_rate.id, tax_rate: params
              }.to_not change{ Spree::TaxRate.with_deleted.count }

              expect(response).to redirect_to spree.admin_tax_rates_url
              expect(tax_rate.reload.name).to eq "Updated Rate"
              expect(tax_rate.amount).to eq 0.1
            end
          end

          context "when the amount is changed" do
            it "duplicates the record and soft-deletes the duplicate" do
              expect {
                spree_put :update, id: tax_rate.id,
                                   tax_rate: { name: "Changed Rate", amount: "0.5" }
              }.to change{ Spree::TaxRate.with_deleted.count }.by(1)

              expect(response).to redirect_to spree.admin_tax_rates_url

              deprecated_rate = tax_rate.reload
              expect(deprecated_rate.name).to eq "Original Rate"
              expect(deprecated_rate.amount).to eq 0.1
              expect(deprecated_rate.deleted?).to be true

              updated_rate = Spree::TaxRate.last
              expect(updated_rate.name).to eq "Changed Rate"
              expect(updated_rate.amount).to eq 0.5
              expect(updated_rate.deleted?).to be false
            end
          end

          context "when included_in_price is changed" do
            it "duplicates the record and soft-deletes the duplicate" do
              expect {
                spree_put :update, id: tax_rate.id,
                                   tax_rate: { name: "Changed Rate", included_in_price: "1" }
              }.to change{ Spree::TaxRate.with_deleted.count }.by(1)

              expect(response).to redirect_to spree.admin_tax_rates_url

              deprecated_rate = tax_rate.reload
              expect(deprecated_rate.name).to eq "Original Rate"
              expect(deprecated_rate.amount).to eq 0.1
              expect(deprecated_rate.included_in_price).to be false
              expect(deprecated_rate.deleted?).to be true

              updated_rate = Spree::TaxRate.last
              expect(updated_rate.name).to eq "Changed Rate"
              expect(updated_rate.amount).to eq 0.1
              expect(updated_rate.included_in_price).to be true
              expect(updated_rate.deleted?).to be false
            end
          end
        end
      end
    end
  end
end
