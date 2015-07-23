require 'open_food_network/reports/report'

module OpenFoodNetwork::Reports
  class TestReport < Report
    header 'One', 'Two', 'Three', 'Four'

    columns do
      column { |o| o[:one] }
      column { |o| o[:two] }
      column { |o| o[:three] }
      column { |o| o[:four] }
    end

    organise do
      group { |o| o[:one] }
      sort  { |o| o[:two] }

      organise do
        group { |o| o[:three] }
        sort  { |o| o[:four] }
      end
    end
  end

  describe Report do
    let(:report) { TestReport.new }
    let(:rules_head) { TestReport.class_variable_get(:@@rules_head) }
    let(:data) { {one: 1, two: 2, three: 3, four: 4} }

    it "returns the header" do
      report.header.should == %w(One Two Three Four)
    end

    it "returns columns as an array of procs" do
      report.columns[0].call(data).should == 1
      report.columns[1].call(data).should == 2
      report.columns[2].call(data).should == 3
      report.columns[3].call(data).should == 4
    end

    describe "rules" do
      let(:group_by) { rules_head.to_h[:group_by] }
      let(:sort_by) { rules_head.to_h[:sort_by] }
      let(:next_group_by) { rules_head.next.to_h[:group_by] }
      let(:next_sort_by) { rules_head.next.to_h[:sort_by] }

      it "constructs the head of the rules list" do
        group_by.call(data).should == 1
        sort_by.call(data).should == 2
      end

      it "constructs nested rules" do
        next_group_by.call(data).should == 3
        next_sort_by.call(data).should == 4
      end
    end
  end
end
