# frozen_string_literal: true

RSpec.describe EnterpriseFeesBulkUpdate do
  describe "error reporting" do
    let(:enterprise_fee) { create(:enterprise_fee) }
    let(:base_attributes) do
      attributes = enterprise_fee.attributes.symbolize_keys
      attributes[:calculator_type] = enterprise_fee.calculator_type
      attributes[:calculator_attributes] = enterprise_fee.calculator.attributes
      attributes
    end
    let(:valid_attributes) do
      set_attributes = {
        collection_attributes: {
          "0" => base_attributes
        }
      }
      ActionController::Parameters.new(set_attributes).permit!
    end
    let(:invalid_attributes) do
      base_attributes[:inherits_tax_category] = "true"
      base_attributes[:calculator_type] = EnterpriseFee::PER_ORDER_CALCULATORS.first
      base_attributes[:calculator_attributes].merge!(preferred_amount: "%12")
      set_attributes = {
        collection_attributes: {
          "0" => base_attributes
        }
      }
      ActionController::Parameters.new(set_attributes).permit!
    end
    let(:loaded_fees) { [enterprise_fee] }

    it "creates a valid form with valid parameters" do
      subject = EnterpriseFeesBulkUpdate.new(valid_attributes, loaded_fees)
      subject.save
      expect(subject).to be_valid
    end

    it "passes up errors from EnterpriseFee creation" do
      enterprise_fee_set = instance_double(Sets::EnterpriseFeeSet, save: false)
      test_errors = ActiveModel::Errors.new(enterprise_fee_set)
      test_errors.add(:base, "error with model creation")
      allow(enterprise_fee_set).to receive(:errors).and_return(test_errors)
      allow(Sets::EnterpriseFeeSet).to receive(:new).and_return(enterprise_fee_set)

      subject = EnterpriseFeesBulkUpdate.new(valid_attributes, loaded_fees)
      subject.save
      expect(subject.errors.messages[:base]).to include("error with model creation")
    end

    it "passes up errors with invalid set attributes" do
      subject = EnterpriseFeesBulkUpdate.new(invalid_attributes, loaded_fees)
      subject.save
      expect(subject.errors.messages[:base]).to include(
        "Invalid input. Please use only numbers. For example: 10, 5.5, -20"
      )
      expect(subject.errors.messages[:base])
        .to include("Inheriting the tax category requires a per-item calculator.")
    end
  end
end
