require 'open_food_network/enterprise_issue_validator'

module OpenFoodNetwork
  describe EnterpriseIssueValidator do
    describe "issues" do
      let(:enterprise) { create(:enterprise) }
      let(:eiv) { EnterpriseIssueValidator.new(enterprise) }
      let(:issues) { eiv.issues }

      it "reports enterprises requiring email confirmation" do
        eiv.stub(:shipping_methods_ok?) { true }
        eiv.stub(:payment_methods_ok?) { true }
        eiv.stub(:confirmed?) { false }

        issues.count.should == 1
        issues.first[:description].should include "Email confirmation is pending"
      end
    end

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
