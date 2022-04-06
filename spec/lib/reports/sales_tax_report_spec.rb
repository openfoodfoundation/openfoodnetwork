# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module SalesTax
      describe SalesTaxReport do
        let(:user) { create(:user) }
        let(:report) { SalesTaxReport.new(user, {}) }

        describe "calculating totals for line items" do
          let(:li1) { double(:line_item, quantity: 1, amount: 12) }
          let(:li2) { double(:line_item, quantity: 2, amount: 24) }
          let(:totals) { report.__send__(:totals_of, [li1, li2]) }

          before do
            allow(report).to receive(:tax_included_in).and_return(2, 4)
          end

          it "calculates total quantity" do
            expect(totals[:items]).to eq(3)
          end

          it "calculates total price" do
            expect(totals[:items_total]).to eq(36)
          end

          context "when floating point math would result in fractional cents" do
            let(:li1) { double(:line_item, quantity: 1, amount: 0.11) }
            let(:li2) { double(:line_item, quantity: 2, amount: 0.12) }

            it "rounds to the nearest cent" do
              expect(totals[:items_total]).to eq(0.23)
            end
          end

          it "calculates the taxable total price" do
            expect(totals[:taxable_total]).to eq(36)
          end

          it "calculates sales tax" do
            expect(totals[:sales_tax]).to eq(6)
          end

          context "when there is no tax on a line item" do
            before do
              allow(report).to receive(:tax_included_in) { 0 }
            end

            it "does not appear in taxable total" do
              expect(totals[:taxable_total]).to eq(0)
            end

            it "still appears on items total" do
              expect(totals[:items_total]).to eq(36)
            end

            it "does not register sales tax" do
              expect(totals[:sales_tax]).to eq(0)
            end
          end
        end
      end
    end
  end
end
