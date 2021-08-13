# frozen_string_literal: true

require 'spec_helper'

describe BatchEnterpriseEnterpriseFeesCountQuery do
  let(:enterprise1) { create(:enterprise) }
  let(:enterprise2) { create(:enterprise) }

  context "when querying enterprises that have no enterprise fees" do
    let(:enterprise_ids) { [enterprise1.id] }

    it do
      expect(BatchEnterpriseEnterpriseFeesCountQuery.call(enterprise_ids)).to eq({})
    end
  end

  context "when querying enterprises that have some enterprise fees" do
    let(:enterprise_ids) { [enterprise1.id, enterprise2.id] }

    before do
      create(:enterprise_fee, enterprise: enterprise1)
      create(:enterprise_fee, enterprise: enterprise2)
      create(:enterprise_fee, enterprise: enterprise2)
    end

    it do
      expect(BatchEnterpriseEnterpriseFeesCountQuery.call(enterprise_ids)).to eq(
        {
          enterprise1.id => 1,
          enterprise2.id => 2
        }
      )
    end
  end
end
