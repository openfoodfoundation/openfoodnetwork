# frozen_string_literal: true

require 'spec_helper'

describe BatchEnterpriseProducerPropertiesCountQuery do
  let(:enterprise1) { create(:enterprise) }
  let(:enterprise2) { create(:enterprise) }

  context "when querying enterprises that have no producer properties" do
    let(:enterprise_ids) { [enterprise1.id] }

    it "returns a hash but it won't include data for enterprises which have no producer properties" do
      expect(BatchEnterpriseProducerPropertiesCountQuery.call(enterprise_ids)).to eq({})
    end
  end

  context "when querying enterprises that have some producer properties" do
    let(:enterprise_ids) { [enterprise1.id, enterprise2.id] }

    before do
      create(:producer_property, producer: enterprise1, property: create(:property))
      create(:producer_property, producer: enterprise2, property: create(:property))
      create(:producer_property, producer: enterprise2, property: create(:property))
    end

    it "returns a hash containing the number of producer properties for each enterprise id" do
      expect(BatchEnterpriseProducerPropertiesCountQuery.call(enterprise_ids)).to eq(
        {
          enterprise1.id => 1,
          enterprise2.id => 2
        }
      )
    end
  end
end
