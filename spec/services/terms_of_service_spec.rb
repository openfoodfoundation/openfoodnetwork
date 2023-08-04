# frozen_string_literal: true

require 'spec_helper'

describe TermsOfService do
  let(:customer) { create(:customer) }
  let(:distributor) { create(:distributor_enterprise) }

  context "a customer has not accepted the terms of service" do
    before do
      allow(customer).to receive(:terms_and_conditions_accepted_at) { nil }
    end

    it "returns false" do
      expect(TermsOfService.tos_accepted?(customer)).to be false
    end
  end

  context "a customer has accepted the platform terms of service" do
    before do
      allow(customer).to receive(:terms_and_conditions_accepted_at) { 1.week.ago }
      allow(TermsOfServiceFile).to receive(:updated_at) { 2.weeks.ago }
    end

    it "should reflect whether the platform TOS have been accepted since the last update" do
      expect {
        allow(TermsOfServiceFile).to receive(:updated_at) { Time.zone.now }
      }.to change {
        TermsOfService.tos_accepted?(customer)
      }.from(true).to(false)
    end
  end

  context "a customer has accepted the distributor terms of service" do
    before do
      allow(customer).to receive(:terms_and_conditions_accepted_at) { 1.week.ago }
      allow(distributor).to receive(:terms_and_conditions_blob) {
        ActiveStorage::Blob.new(created_at: 2.weeks.ago)
      }
    end

    it "should reflect whether the platform TOS have been accepted since the last update" do
      expect {
        allow(distributor).to receive(:terms_and_conditions_updated_at) { Time.zone.now }
        allow(distributor).to receive(:terms_and_conditions_blob) {
          ActiveStorage::Blob.new(created_at: Time.zone.now)
        }
      }.to change {
        TermsOfService.tos_accepted?(customer, distributor)
      }.from(true).to(false)
    end
  end
end
