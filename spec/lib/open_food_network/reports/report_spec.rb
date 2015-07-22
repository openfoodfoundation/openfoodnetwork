require 'open_food_network/reports/report'

module OpenFoodNetwork::Reports
  class TestReport < Report
    header 'One', 'Two', 'Three'

    columns do
      column { |o| o[:one] }
      column { |o| o[:two] }
      column { |o| o[:three] }
    end
  end

  describe Report do
    let(:report) { TestReport.new }
    let(:data) { {one: 1, two: 2, three: 3} }

    it "returns the header" do
      report.header.should == %w(One Two Three)
    end

    it "returns columns as an array of procs" do
      report.columns[0].call(data).should == 1
      report.columns[1].call(data).should == 2
      report.columns[2].call(data).should == 3
    end
  end
end
