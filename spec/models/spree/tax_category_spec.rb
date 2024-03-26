# frozen_string_literal: true

require 'spec_helper'

describe Spree::TaxCategory do
  describe "associations" do
    it { is_expected.to have_many(:tax_rates).dependent(:destroy) }
    it { is_expected.to have_many(:variants).dependent(:restrict_with_error) }
  end

  context 'default tax category' do
    let(:tax_category) { create(:tax_category) }
    let(:new_tax_category) { create(:tax_category) }

    before do
      tax_category.update_column(:is_default, true)
    end

    it "should undefault the previous default tax category" do
      new_tax_category.update({ is_default: true })
      expect(new_tax_category.is_default).to be_truthy

      tax_category.reload
      expect(tax_category.is_default).to be_falsy
    end

    it "undefaults the previous default tax category
      except when updating the existing default tax category" do
      tax_category.update_column(:description, "Updated description")

      tax_category.reload
      expect(tax_category.is_default).to be_truthy
    end
  end
end
