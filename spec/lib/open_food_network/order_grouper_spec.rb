require 'spec_helper'

module OpenFoodNetwork
  describe OrderGrouper do

    before(:each) do
        @items = [1, 2, 3, 4]
    end

    context "constructing the table" do
      it "should build a tree then build a table" do
        rules = [ { group_by: Proc.new { |sentence| sentence.paragraph.chapter }, sort_by: Proc.new { |chapter| chapter.name }, summary_columns: [Proc.new { |is| is.first.paragraph.chapter.name }, Proc.new { |is| "TOTAL" }, Proc.new { |is| "" }, Proc.new { |is| is.sum {|i| i.property1 } } ] }, 
        { group_by: Proc.new { |sentence| sentence.paragraph }, sort_by: Proc.new { |paragraph| paragraph.name } } ]
        columns = [Proc.new { |is| is.first.paragraph.chapter.name }, Proc.new { |is| is.first.paragraph.name }, Proc.new { |is| is.first.name }, Proc.new { |is| is.sum {|i| i.property1 } }]

        subject = OrderGrouper.new rules, columns

        tree = double(:tree)
        subject.should_receive(:build_tree).with(@items, rules).and_return(tree)
        subject.should_receive(:build_table).with(tree)

        subject.table(@items)
      end
      
    end

    context "grouping items without rules" do
      it "returns the original array when no rules are provided" do
        rules = []
        column1 = double(:col1)
        column2 = double(:col2)
        columns = [column1, column2]
        subject = OrderGrouper.new rules, columns
        
        rules.should_receive(:clone).and_return(rules)
        subject.build_tree(@items, rules).should == @items
      end
    end

    context "grouping items with rules" do
      
      before(:each) do
        @rule1 = double(:rule1)
        rule2 = double(:rule2)
        @rules = [@rule1, rule2]
        @remaining_rules = [rule2]
        column1 = double(:col1)
        column2 = double(:col2)
        @columns = [column1, column2]
      end
      
      it "builds branches by removing a rule from 'rules' and running group_and_sort" do
        subject = OrderGrouper.new @rules, @columns

        @rules.should_receive(:clone).and_return(@rules)
        @rules.should_receive(:delete_at).with(0)
        grouped_tree = double(:grouped_tree)
        subject.should_receive(:group_and_sort).and_return(grouped_tree)

        subject.build_tree(@items, @rules).should == grouped_tree
      end

      it "separates the first rule from rules before sending to group_and_sort" do
        subject = OrderGrouper.new @rules, @columns

        grouped_tree = double(:grouped_tree)
        subject.should_receive(:group_and_sort).with(@rule1, @rules[1..-1], @items).and_return(grouped_tree)

        subject.build_tree(@items, @rules).should == grouped_tree
      end

      it "should group, then sort, send each group to build_tree, and return a branch" do
        summary_columns_object = double(:summary_columns)
        @rule1.stub(:[]).with(:summary_columns) { summary_columns_object }

        subject = OrderGrouper.new @rules, @columns

        number_of_categories = 3
        groups = double(:groups)
        @items.should_receive(:group_by).and_return(groups)
        sorted_groups = {}
        1.upto(number_of_categories) { |i| sorted_groups[i] = double(:group, name: "Group "+ i.to_s ) }
        groups.should_receive(:sort_by).and_return(sorted_groups)
        group = { group1: 1, group2: 2, group3: 3 }
        subject.should_receive(:build_tree).exactly(number_of_categories).times.and_return(group)

        group_tree = {}
        1.upto(number_of_categories) { |i| group_tree[i] = group }
        1.upto(number_of_categories) { |i| group_tree[i][:summary_row] = summary_columns_object }
        subject.group_and_sort(@rule1, @remaining_rules, @items).should == group_tree
      end
    end

    context "building the table Array" do
      before(:each) do
        rule1 = double(:rule1)
        rule2 = double(:rule2)
        @rules = [rule1, rule2]
        @column1 = double(:col1, :call => "Column1")
        @column2 = double(:col2, :call => "Column2")
        @columns = [@column1, @column2]

        sumcol1 = double(:sumcol1, :call => "SumColumn1")
        sumcol2 = double(:sumcol2, :call => "SumColumn2")
        @sumcols = [sumcol1, sumcol2]

        item1 = double(:item1)
        item2 = double(:item2)
        item3 = double(:item3)
        @items1 = [item1, item2]
        @items2 = [item2, item3]
        @items3 = [item3, item1]
      end
      it "should return columns when given an Array" do
        subject = OrderGrouper.new @rules, @columns

        @column1.should_receive(:call)
        @column2.should_receive(:call)

        subject.build_table(@items1).should == [["Column1", "Column2"]]
      end
      
      it "should return a row for each key-value pair when given a Hash" do
        groups = { items1: @items1, items2: @items2, items3: @items3 }

        subject = OrderGrouper.new @rules, @columns

        #subject.should_receive(:build_table).exactly(2).times

        expected_return = []
        groups.length.times { expected_return << ["Column1", "Column2"] }
        subject.build_table(groups).should == expected_return
      end

      it "should return an extra row when a :summary_row key appears in a given Hash" do
        groups = { items1: @items1, items2: @items2, items3: @items3, summary_row: { items: { items2: @items2, items3: @items3 }, columns: @sumcols } }

        subject = OrderGrouper.new @rules, @columns

        expected_return = []
        groups.each do |key, group| 
          if key == :summary_row 
            expected_return << ["SumColumn1", "SumColumn2"]
          else
            expected_return << ["Column1", "Column2"]
          end
        end
        subject.build_table(groups).should == expected_return
      end
    end
  end
end
