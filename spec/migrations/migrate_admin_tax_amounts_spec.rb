# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20210617203927_migrate_admin_tax_amounts'

describe MigrateAdminTaxAmounts do
  subject { MigrateAdminTaxAmounts.new }

  let(:tax_category10) { create(:tax_category) }
  let(:tax_category50) { create(:tax_category) }
  let!(:tax_rate10) { create(:tax_rate, amount: 0.1, tax_category: tax_category10) }
  let!(:tax_rate50) { create(:tax_rate, amount: 0.5, tax_category: tax_category50) }
  let(:adjustment10) { create(:adjustment, amount: 100, included_tax: 10) }
  let(:adjustment50) { create(:adjustment, amount: 100, included_tax: 50) }

  describe '#migrate_admin_taxes!' do
    context "when the adjustment has no tax" do
      let!(:adjustment_without_tax) { create(:adjustment, included_tax: 0) }

      it "doesn't move the tax to an adjustment" do
        expect { subject.migrate_admin_taxes! }.to_not change {
          Spree::Adjustment.count
        }
      end
    end

    context "when the adjustments have tax" do
      before do
        adjustment10; adjustment50
        allow(subject).to receive(:applicable_rates) { [tax_rate10, tax_rate50] }
      end

      it "moves the tax to an adjustment" do
        expect(Spree::Adjustment).to receive(:create!).at_least(:once).and_call_original

        subject.migrate_admin_taxes!
        expect(adjustment10.reload.tax_category).to eq tax_category10
        expect(adjustment50.reload.tax_category).to eq tax_category50

        tax_adjustment10 = Spree::Adjustment.tax.where(adjustable_id: adjustment10).first

        expect(tax_adjustment10.amount).to eq adjustment10.included_tax
        expect(tax_adjustment10.adjustable).to eq adjustment10
        expect(tax_adjustment10.originator).to eq tax_rate10
        expect(tax_adjustment10.state).to eq "closed"
        expect(tax_adjustment10.included).to eq true

        tax_adjustment50 = Spree::Adjustment.tax.where(adjustable_id: adjustment50).first

        expect(tax_adjustment50.amount).to eq adjustment50.included_tax
        expect(tax_adjustment50.adjustable).to eq adjustment50
        expect(tax_adjustment50.originator).to eq tax_rate50
        expect(tax_adjustment50.state).to eq "closed"
        expect(tax_adjustment50.included).to eq true
      end
    end
  end

  describe "#find_tax_rate" do
    before do
      allow(subject).to receive(:applicable_rates) { [tax_rate10, tax_rate50] }
    end

    it "matches rates correctly" do
      expect(subject.find_tax_rate(adjustment10)).to eq(tax_rate10)

      expect(subject.find_tax_rate(adjustment50)).to eq(tax_rate50)
    end

    context "without a perfect match" do
      let(:adjustment45) { create(:adjustment, amount: 100, included_tax: 45) }

      it "finds the closest match" do
        expect(subject.find_tax_rate(adjustment45)).to eq(tax_rate50)
      end
    end
  end

  describe "#applicabe_rates" do
    let(:distributor) { create(:enterprise) }
    let(:order) { create(:order, distributor: distributor) }
    let!(:adjustment) { create(:adjustment, order: order) }

    context "when the order is nil" do
      let(:order) { nil }

      it "returns an empty array" do
        expect(Spree::TaxRate).to_not receive(:match)

        expect(subject.applicable_rates(adjustment)).to eq []
      end
    end

    context "when the order has no distributor" do
      let(:distributor) { nil }

      it "returns an empty array" do
        expect(Spree::TaxRate).to_not receive(:match)

        expect(subject.applicable_rates(adjustment)).to eq []
      end
    end

    context "when the order has a distributor" do
      it "calls TaxRate#match for an array of applicable taxes for the order" do
        expect(Spree::TaxRate).to receive(:match) { [tax_rate10] }

        expect(subject.applicable_rates(adjustment)).to eq [tax_rate10]
      end
    end
  end

  describe '#tax_adjustment_label' do
    let(:tax_rate) { create(:tax_rate, name: "Test Rate", amount: 0.20) }

    context "when a tax rate is given" do
      it "makes a detailed label" do
        expect(subject.tax_adjustment_label(tax_rate)).
          to eq("Test Rate 20.0% (Included in price)")
      end
    end

    context "when the tax rate is nil" do
      it "makes a basic label" do
        expect(subject.tax_adjustment_label(nil)).to eq("Included tax")
      end
    end
  end
end
