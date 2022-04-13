# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/enterprise_issue_validator'

module OpenFoodNetwork
  describe EnterpriseIssueValidator do
    describe "warnings" do
      let(:enterprise_invisible) { create(:enterprise, visible: "only_through_links") }
      let(:warnings) { EnterpriseIssueValidator.new(enterprise_invisible).warnings }

      it "reports invisible enterprises" do
        expect(warnings.count).to eq(1)
        expect(warnings.first[:description]).to include "is not visible"
      end
    end
  end
end
