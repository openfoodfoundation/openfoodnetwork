# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20210406161242_migrate_enterprise_fee_tax_amounts'

describe MigrateEnterpriseFeeTaxAmounts do
  subject { MigrateEnterpriseFeeTaxAmounts.new }

  let(:tax_category_regular) { create(:tax_category) }
  let(:tax_rate_regular) { create(:tax_rate, tax_category: tax_category_regular) }
  let(:tax_category_inherited) { create(:tax_category) }
  let(:tax_rate_inherited) { create(:tax_rate, tax_category: tax_category_inherited) }
  let(:enterprise_fee_regular) { create(:enterprise_fee, inherits_tax_category: false,
                                        tax_category: tax_category_regular) }
  let(:enterprise_fee_inheriting) { create(:enterprise_fee, inherits_tax_category: true) }
  let(:fee_without_tax) { create(:adjustment, originator: enterprise_fee_regular, included_tax: 0) }
  let(:fee_regular) { create(:adjustment, originator: enterprise_fee_regular, included_tax: 1.23) }
  let(:fee_inheriting) { create(:adjustment, originator: enterprise_fee_inheriting,
                                adjustable: line_item, included_tax: 4.56) }
  let(:product) { create(:product, tax_category: tax_category_inherited) }
  let!(:line_item) { create(:line_item, variant: product.variants.first) }

  describe '#migrate_enterprise_fee_taxes!' do
    context "when the fee has no tax" do
      before { fee_without_tax }

      it "doesn't move the tax to an adjustment" do
        expect(Spree::Adjustment).to_not receive(:create!)

        subject.migrate_enterprise_fee_taxes!
      end
    end

    context "when the fee has (non-inheriting) tax" do
      before { fee_regular; tax_rate_regular }

      it "moves the tax to an adjustment" do
        expect(Spree::Adjustment).to receive(:create!).and_call_original

        subject.migrate_enterprise_fee_taxes!

        expect(fee_regular.reload.tax_category).to eq tax_category_regular

        tax_adjustment = Spree::Adjustment.tax.last

        expect(tax_adjustment.amount).to eq fee_regular.included_tax
        expect(tax_adjustment.adjustable).to eq fee_regular
        expect(tax_adjustment.originator).to eq tax_rate_regular
        expect(tax_adjustment.state).to eq "closed"
        expect(tax_adjustment.included).to eq true
      end
    end

    context "when the fee has tax and inherits tax category from product" do
      before { fee_inheriting; tax_rate_inherited }

      it "moves the tax to an adjustment" do
        expect(Spree::Adjustment).to receive(:create!).and_call_original

        subject.migrate_enterprise_fee_taxes!

        expect(fee_inheriting.reload.tax_category).to eq tax_category_inherited

        tax_adjustment = Spree::Adjustment.tax.last

        expect(tax_adjustment.amount).to eq fee_inheriting.included_tax
        expect(tax_adjustment.adjustable).to eq fee_inheriting
        expect(tax_adjustment.originator).to eq tax_rate_inherited
        expect(tax_adjustment.state).to eq "closed"
        expect(tax_adjustment.included).to eq true
      end
    end

    context "when the fee has a soft-deleted EnterpriseFee" do
      before do
        enterprise_fee_regular.update_columns(deleted_at: Time.zone.now)
        fee_regular
        tax_rate_regular
      end

      it "moves the tax to an adjustment" do
        expect(Spree::Adjustment).to receive(:create!).and_call_original

        subject.migrate_enterprise_fee_taxes!

        expect(fee_regular.reload.tax_category).to eq tax_category_regular

        tax_adjustment = Spree::Adjustment.tax.last

        expect(tax_adjustment.amount).to eq fee_regular.included_tax
        expect(tax_adjustment.adjustable).to eq fee_regular
        expect(tax_adjustment.originator).to eq tax_rate_regular
        expect(tax_adjustment.state).to eq "closed"
        expect(tax_adjustment.included).to eq true
      end
    end

    context "when the fee has a hard-deleted EnterpriseFee" do
      before do
        fee_regular
        tax_rate_regular
        EnterpriseFee.delete_all
        expect(fee_regular.reload.originator).to eq nil
      end

      it "moves the tax to an adjustment" do
        expect(Spree::Adjustment).to receive(:create!).and_call_original

        subject.migrate_enterprise_fee_taxes!

        expect(fee_regular.reload.tax_category).to eq nil

        tax_adjustment = Spree::Adjustment.tax.last

        expect(tax_adjustment.amount).to eq fee_regular.included_tax
        expect(tax_adjustment.adjustable).to eq fee_regular
        expect(tax_adjustment.originator_id).to eq nil
        expect(tax_adjustment.originator_type).to eq "Spree::TaxRate"
        expect(tax_adjustment.state).to eq "closed"
        expect(tax_adjustment.included).to eq true
      end
    end
  end

  describe '#tax_category_for' do
    it "returns the correct tax category when not inherited from line item" do
      expect(subject.tax_category_for(fee_regular)).to eq tax_category_regular
    end

    it "returns the correct tax category when inherited from line item" do
      expect(subject.tax_category_for(fee_inheriting)).to eq tax_category_inherited
    end

    it "returns nil if the associated EnterpriseFee was hard-deleted and can't be found" do
      fee_regular
      EnterpriseFee.delete_all
      fee_regular.reload

      expect(subject.tax_category_for(fee_regular)).to eq nil
    end
  end

  describe '#tax_rate_for' do
    let!(:tax_category) { create(:tax_category) }
    let!(:tax_rate) { create(:tax_rate, tax_category: tax_category) }

    context "when a tax rate exists" do
      it "returns a valid tax rate" do
        expect(subject.tax_rate_for(tax_category)).to eq tax_rate
      end
    end

    context "when the tax category is nil" do
      it "returns nil" do
        expect(subject.tax_rate_for(nil)).to eq nil
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
        expect(subject.tax_adjustment_label(nil)).
          to eq("Included tax")
      end
    end
  end
end
