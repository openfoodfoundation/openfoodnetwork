require 'open_food_network/reports/report'

module OpenFoodNetwork::Reports
  class TestReport < Report
    header 'One', 'Two', 'Three'
  end

  describe Report do
    let(:report) { TestReport.new }

    it "returns the header" do
      report.header.should == %w(One Two Three)
    end
  end
end
