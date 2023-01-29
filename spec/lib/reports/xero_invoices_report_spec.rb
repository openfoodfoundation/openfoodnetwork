# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module XeroInvoices
      describe Base do
        subject { Base.new user, {} }

        let(:user) { create(:user) }

        describe "option defaults" do
          let(:report) { Base.new user }

          around { |example| Timecop.travel(Time.zone.local(2015, 5, 5, 14, 0, 0)) { example.run } }

          it "uses defaults when blank params are passed" do
            expect(report.params).to eq(invoice_date: Date.civil(2015, 5, 5),
                                        due_date: Date.civil(2015, 6, 5),
                                        account_code: 'food sales',
                                        report_subtype: 'summary',
                                        q: {})
          end
        end

        describe "summary rows" do
          let(:report) {
            Base.new(user, params)
          }
          let(:params) {
            {
              initial_invoice_number: '', invoice_date: '', due_date: '',
              account_code: ''
            }
          }
          let(:order) { double(:order) }
          let(:summary_rows) { report.__send__(:summary_rows_for_order, order, 1, {}) }

          before do
            allow(report).to receive(:produce_summary_rows)  { ['produce'] }
            allow(report).to receive(:fee_summary_rows)      { ['fee'] }
            allow(report).to receive(:shipping_summary_rows) { ['shipping'] }
            allow(report).to receive(:payment_summary_rows)  { ['payment'] }
            allow(report).to receive(:admin_adjustment_summary_rows) { ['admin'] }
          end

          it "displays produce summary rows when summary report" do
            allow(report).to receive(:detail?) { false }
            expect(summary_rows).to include 'produce'
          end

          it "does not display produce summary rows when detail report" do
            allow(report).to receive(:detail?) { true }
            expect(summary_rows).not_to include 'produce'
          end

          it "displays fee summary rows when summary report" do
            allow(report).to receive(:detail?) { false }
            expect(summary_rows).to include 'fee'
          end

          it "displays fee summary rows when detail report" do
            allow(report).to receive(:detail?) { true }
            expect(summary_rows).to include 'fee'
          end

          it "always displays shipping summary rows" do
            expect(summary_rows).to include 'shipping'
          end

          it "displays admin adjustment summary rows when summary report" do
            expect(summary_rows).to include 'admin'
          end

          it "does not display admin adjustment summary rows when detail report" do
            allow(report).to receive(:detail?) { true }
            expect(summary_rows).not_to include 'admin'
          end
        end

        describe "generating invoice numbers" do
          let(:order) { double(:order, number: 'R731032860') }

          describe "when no initial invoice number is given" do
            it "returns the order number" do
              expect(subject.send(:invoice_number_for, order, 123)).to eq('R731032860')
            end
          end

          describe "when an initial invoice number is given" do
            subject { Base.new(user, { initial_invoice_number: '123' }) }

            it "increments the number by the index" do
              expect(subject.send(:invoice_number_for, order, 456)).to eq(579)
            end
          end
        end
      end
    end
  end
end
