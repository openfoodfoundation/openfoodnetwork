require 'open_food_network/reports/report'

module OpenFoodNetwork::Reports
  class TestReport < Report
    header 'One', 'Two', 'Three', 'Four'
  end

  describe Report do
    let(:report) { TestReport.new }

    it "returns the header" do
      expect(report.header).to eq(%w(One Two Three Four))
    end
  end
end
