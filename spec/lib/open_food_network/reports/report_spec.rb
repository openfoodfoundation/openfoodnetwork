require 'open_food_network/reports/report'

module OpenFoodNetwork::Reports
  P1 = proc { |o| o[:one] }
  P2 = proc { |o| o[:two] }
  P3 = proc { |o| o[:three] }
  P4 = proc { |o| o[:four] }

  class TestReport < Report
    header 'One', 'Two', 'Three', 'Four'

    columns do
      column(&P1)
      column(&P2)
      column(&P3)
      column(&P4)
    end

    organise do
      group(&P1)
      sort(&P2)

      organise do
        group(&P3)
        sort(&P4)

        summary_row do
          column(&P1)
          column(&P4)
        end
      end
    end
  end

  class HelperReport < Report
    columns do
      column { |o| my_helper(o) }
    end

    private

    def self.my_helper(o)
      o[:one]
    end
  end

  describe Report do
    let(:report) { TestReport.new }
    let(:helper_report) { HelperReport.new }
    let(:rules_head) { TestReport._rules_head }
    let(:data) { { one: 1, two: 2, three: 3, four: 4 } }

    it "returns the header" do
      expect(report.header).to eq(%w(One Two Three Four))
    end

    it "returns columns as an array of procs" do
      expect(report.columns[0].call(data)).to eq(1)
      expect(report.columns[1].call(data)).to eq(2)
      expect(report.columns[2].call(data)).to eq(3)
      expect(report.columns[3].call(data)).to eq(4)
    end

    it "supports helpers when outputting columns" do
      expect(helper_report.columns[0].call(data)).to eq(1)
    end

    describe "rules" do
      let(:group_by) { rules_head.to_h[:group_by] }
      let(:sort_by) { rules_head.to_h[:sort_by] }
      let(:next_group_by) { rules_head.next.to_h[:group_by] }
      let(:next_sort_by) { rules_head.next.to_h[:sort_by] }
      let(:next_summary_columns) { rules_head.next.to_h[:summary_columns] }

      it "constructs the head of the rules list" do
        expect(group_by.call(data)).to eq(1)
        expect(sort_by.call(data)).to eq(2)
      end

      it "constructs nested rules" do
        expect(next_group_by.call(data)).to eq(3)
        expect(next_sort_by.call(data)).to eq(4)
      end

      it "constructs summary columns for rules" do
        expect(next_summary_columns[0].call(data)).to eq(1)
        expect(next_summary_columns[1].call(data)).to eq(4)
      end
    end

    describe "outputting rules" do
      it "outputs the rules" do
        expect(report.rules).to eq([{ group_by: P1, sort_by: P2 },
                                    { group_by: P3, sort_by: P4, summary_columns: [P1, P4] }])
      end
    end
  end
end
