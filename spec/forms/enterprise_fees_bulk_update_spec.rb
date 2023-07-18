# frozen_string_literal: true

require 'spec_helper'

describe EnterpriseFeesBulkUpdate do
  describe "error reporting" do
    let(:enterprise_fee) { build_stubbed(:enterprise_fee) }
    let(:base_attributes) do
      attributes = enterprise_fee.attributes.symbolize_keys
      attributes[:calculator_type] = enterprise_fee.calculator_type
      attributes[:calculator_attributes] = enterprise_fee.calculator.attributes
      attributes
    end
    let(:valid_attributes) do
      set_attributes = {
        sets_enterprise_fee_set: {
          collection_attributes: {
            "0" => base_attributes
          }
        }
      }
      ActionController::Parameters.new(set_attributes)
    end
    let(:invalid_attributes) do
      base_attributes[:inherits_tax_category] = "true"
      base_attributes[:calculator_type] = EnterpriseFee::PER_ORDER_CALCULATORS.first
      base_attributes[:calculator_attributes].merge!(preferred_amount: "%12")
      set_attributes = {
        sets_enterprise_fee_set: {
          collection_attributes: {
            "0" => base_attributes
          }
        }
      }
      ActionController::Parameters.new(set_attributes)
    end

    it "creates a valid form with valid parameters" do
      subject = EnterpriseFeesBulkUpdate.new(valid_attributes)
      subject.save
      expect(subject).to be_valid
    end

    it "passes up errors from EnterpriseFee creation" do
      enterprise_fee_set = instance_double(Sets::EnterpriseFeeSet, save: false)
      test_errors = ActiveModel::Errors.new(enterprise_fee_set)
      test_errors.add(:base, "error with model creation")
      allow(enterprise_fee_set).to receive(:errors).and_return(test_errors)
      allow(Sets::EnterpriseFeeSet).to receive(:new).and_return(enterprise_fee_set)

      subject = EnterpriseFeesBulkUpdate.new(valid_attributes)
      subject.save
      expect(subject.errors.messages[:base]).to include("error with model creation")
    end

    it "passes up errors with invalid set attributes" do
      subject = EnterpriseFeesBulkUpdate.new(invalid_attributes)
      subject.save
      expect(subject.errors.messages[:base]).to include(I18n.t(:calculator_preferred_value_error))
      expect(subject.errors.messages[:base])
        .to include(
          I18n.t(
            'activerecord.errors.models.enterprise_fee.inherit_tax_requires_per_item_calculator'
          )
        )
    end
  end
end
