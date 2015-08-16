require 'open_food_network/lettuce_share_report'

module OpenFoodNetwork
  describe LettuceShareReport do
    let(:user) { create(:user) }
    let(:report) { LettuceShareReport.new user }
    let(:v) { create(:variant) }

    describe "grower and method" do
      it "shows just the producer when there is no certification" do
        report.stub(:producer_name) { "Producer" }
        report.stub(:certification) { "" }

        report.send(:grower_and_method, v).should == "Producer"
      end

      it "shows producer and certification when a certification is present" do
        report.stub(:producer_name) { "Producer" }
        report.stub(:certification) { "Method" }

        report.send(:grower_and_method, v).should == "Producer (Method)"
      end
    end
  end
end
