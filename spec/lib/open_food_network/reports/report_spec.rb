require 'spec_helper'

module OpenFoodNetwork::Reports
  P1 = Proc.new { |o| o[:one] }
  P2 = Proc.new { |o| o[:two] }
  P3 = Proc.new { |o| o[:three] }
  P4 = Proc.new { |o| o[:four] }

  class TestReport < Report
    header 'One', 'Two', 'Three', 'Four'

    columns do
      column &P1
      column &P2
      column &P3
      column &P4
    end

    organise do
      group &P1
      sort  &P2

      organise do
        group &P3
        sort  &P4

        summary_row do
          column &P1
          column &P4
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
    context 'inheritance methods to search and filter for ui-grid reports' do
      let(:user) { create(:admin_user) }

      context 'blank object' do
        let(:report) { Report.new(user, {query: 'keyword'}, ['order']) }
        it 'new instance accepts 3 arguments' do
          expect(report.params).to eq({query: 'keyword'})
        end

        it 'gets search object via permissions' do
          expect(report.search).to be_instance_of(Ransack::Search)
        end

        it 'returns empty array of line_items' do
          expect(report.table_items).to be_empty
        end
      end

      context 'with line items' do
        let(:enterprise) { create(:distributor_enterprise) }
        let(:order_cycle) { create(:simple_order_cycle) }
        let(:order) { create(:order, completed_at: 1.day.ago, order_cycle: order_cycle, distributor: enterprise) }
        let(:line_item) { build(:line_item) }
        let(:report) { Report.new(user) }

        before { order.line_items << line_item }

        it 'returns one line_item' do
          expect(report.table_items).to eq([line_item])
        end
      end
    end

    context 'methods for creating report tables' do
      let(:report) { TestReport.new }
      let(:helper_report) { HelperReport.new }
      let(:rules_head) { TestReport._rules_head }
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

      it "supports helpers when outputting columns" do
        helper_report.columns[0].call(data).should == 1
      end

      describe "rules" do
        let(:group_by) { rules_head.to_h[:group_by] }
        let(:sort_by) { rules_head.to_h[:sort_by] }
        let(:next_group_by) { rules_head.next.to_h[:group_by] }
        let(:next_sort_by) { rules_head.next.to_h[:sort_by] }
        let(:next_summary_columns) { rules_head.next.to_h[:summary_columns] }

        it "constructs the head of the rules list" do
          group_by.call(data).should == 1
          sort_by.call(data).should == 2
        end

        it "constructs nested rules" do
          next_group_by.call(data).should == 3
          next_sort_by.call(data).should == 4
        end

        it "constructs summary columns for rules" do
          next_summary_columns[0].call(data).should == 1
          next_summary_columns[1].call(data).should == 4
        end
      end

      describe "outputting rules" do
        it "outputs the rules" do
          report.rules.should == [{group_by: P1, sort_by: P2},
                                  {group_by: P3, sort_by: P4, summary_columns: [P1, P4]}]
        end
      end
    end
  end
end
