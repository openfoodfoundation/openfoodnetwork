# frozen_string_literal: true

require 'spec_helper'

describe BatchEnterprisePaymentMethodsCountQuery do
  let(:enterprise1) { create(:enterprise) }
  let(:enterprise2) { create(:enterprise) }

  context "when querying enterprises that have no payment methods" do
    let(:enterprise_ids) { [enterprise1.id] }

    it "returns a hash but it won't include data for enterprises which have no payment methods" do
      expect(BatchEnterprisePaymentMethodsCountQuery.call(enterprise_ids)).to eq({})
    end
  end

  context "when querying enterprises that have some payment methods" do
    let(:enterprise_ids) { [enterprise1.id, enterprise2.id] }

    before do
      create(:payment_method, distributors: [enterprise1])
      create(:payment_method, distributors: [enterprise2])
      create(:payment_method, distributors: [enterprise2])
    end

    it "returns a hash containing the number of payment methods for each enterprise id" do
      expect(BatchEnterprisePaymentMethodsCountQuery.call(enterprise_ids)).to eq(
        {
          enterprise1.id => 1,
          enterprise2.id => 2
        }
      )
    end
  end
end
