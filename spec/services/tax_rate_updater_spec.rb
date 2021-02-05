# frozen_string_literal: true

require 'spec_helper'

describe TaxRateUpdater do
  let!(:old_tax_rate) {
    create(:tax_rate, name: "Test Rate", amount: 0.2, calculator: Calculator::DefaultTax.new)
  }
  let(:params) { { amount: 0.5 } }
  let(:service) { TaxRateUpdater.new(old_tax_rate, params) }
  let(:new_tax_rate) { service.updated_rate }

  describe "#updated_rate" do
    it "returns a cloned (unsaved) tax rate with the new attributes assigned" do
      expect(new_tax_rate).to_not be old_tax_rate
      expect(new_tax_rate.amount).to eq params[:amount]
      expect(new_tax_rate.id).to be_nil
      expect(new_tax_rate.calculator.class).to eq old_tax_rate.calculator.class
      expect(new_tax_rate).to be_valid
    end
  end

  describe "#transition_rate!" do
    it "saves the new tax_rate and deletes the old tax_rate" do
      expect(new_tax_rate).to receive(:save).and_call_original
      expect(old_tax_rate).to receive(:destroy).and_call_original

      expect(service.transition_rate!).to be_truthy

      expect(new_tax_rate.reload.persisted?).to be true
      expect(old_tax_rate.reload.deleted?).to be true
    end

    context "when saving the new tax_rate fails" do
      it "does not delete the old tax_rate and returns a falsey value" do
        expect(new_tax_rate).to receive(:save) { false }
        expect(old_tax_rate).to_not receive(:destroy)

        expect(service.transition_rate!).to_not be_truthy
      end
    end
  end
end
