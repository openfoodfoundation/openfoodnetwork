require 'open_food_network/enterprise_issue_validator'

module OpenFoodNetwork
  describe EnterpriseIssueValidator do
    describe "warnings" do
      let(:enterprise_invisible) { create(:enterprise, visible: false) }
      let(:warnings) { EnterpriseIssueValidator.new(enterprise_invisible).warnings }

      it "reports invisible enterprises" do
        warnings.count.should == 1
        warnings.first[:description].should include "is not visible"
      end
    end
  end
end
