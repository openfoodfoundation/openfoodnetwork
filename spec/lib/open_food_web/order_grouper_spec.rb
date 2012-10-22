#require 'spec_helper'

#module OpenFoodWeb
#  describe OrderGrouper do
#
#    before(:each) do
#      @orders = []
#      distributor_address = create(:address, :address1 => "distributor address", :city => 'The Shire', :zipcode => "1234")
#      distributor = create(:distributor, :pickup_address => distributor_address)
#
#      @supplier1 = create(:supplier)
#      @variant1 = create(:variant)
#      @variant1.product.supplier = @supplier1
#      @variant1.product.save!
#      shipping_method = create(:shipping_method)
#      product_distribution = create(:product_distribution, :product => @variant1.product, :distributor => distributor, :shipping_method => create(:shipping_method))
#      shipping_instructions = "pick up on thursday please!"
#
#      bill_address1 = create(:address)
#      order1 = create(:order, :distributor => distributor, :bill_address => bill_address1, :special_instructions => shipping_instructions)
#      line_item11 = create(:line_item, :variant => @variant1, :order => order1)
#      order1.line_items << line_item11
#      @orders << order1
#
#      bill_address2 = create(:address)
#      order2 = create(:order, :distributor => distributor, :bill_address => bill_address2, :special_instructions => shipping_instructions)
#      line_item21 = create(:line_item, :variant => @variant1, :order => order2)
#      order2.line_items << line_item21
#
#      @variant2 = create(:variant)
#      @variant2.product.supplier = @supplier1
#      @variant2.product.save!
#      product_distribution = create(:product_distribution, :product => @variant2.product, :distributor => distributor, :shipping_method => create(:shipping_method))
#
#      line_item22 = create(:line_item, :variant => @variant2, :order => order2)
#      order2.line_items << line_item22
#      @orders << order2
#
#      @supplier2 = create(:supplier)
#      @variant3 = create(:variant)
#      @variant3.product.supplier = @supplier2
#      @variant3.product.save!
#      product_distribution = create(:product_distribution, :product => @variant3.product, :distributor => distributor, :shipping_method => create(:shipping_method))

#      bill_address3 = create(:address)
#      order3 = create(:order, :distributor => distributor, :bill_address => bill_address3, :special_instructions => shipping_instructions)
#      line_item31 = create(:line_item, :variant => @variant3, :order => order3)
#      order3.line_items << line_item31
#      @orders << order3
#    end
    
#    context "when grouping by supplier, then product, then variant" do
#      group_rules = [ { group_by: Proc.new { |li| li.variant.product.supplier }, sort_by: Proc.new { |supplier| supplier.name } }, { group_by: Proc.new { |li| li.variant.product }, sort_by: Proc.new { |product| product.name } }, { group_by: Proc.new { |li| li.variant }, sort_by: Proc.new { |variant| variant.options_text } } ]
#      column_properties = [ Proc.new { |lis| lis.first.variant.product.supplier.name },  Proc.new { |lis| lis.first.variant.product.name }, Proc.new { |lis| "UNIT SIZE" }, Proc.new { |lis| lis.first.variant.options_text }, Proc.new { |lis| lis.first.variant.weight }, Proc.new { |lis|  lis.sum { |li| li.quantity } }, Proc.new { |lis| lis.sum { |li| li.max_quantity || 0 } } ]

#      it "should return a Hash with one key for each supplier represented by the orders" do
#        subject = OrderGrouper.new group_rules, column_properties
        
#        line_items = @orders.map { |o| o.line_items }.flatten

#        groups = subject.grouper_sorter(line_items, group_rules)
#        groups.class.should == Hash
#        groups.length.should == 2
#      end

#      it "should group items over multiple levels according to group by rules" do
#        subject = OrderGrouper.new group_rules, column_properties
        
#        line_items = @orders.map { |o| o.line_items }.flatten

#        groups = subject.grouper_sorter(line_items, group_rules)
#        groups[@supplier1].length.should == 2
#        groups[@supplier2].length.should == 1
#      end

#      it "should return a table as an array" do
#        subject = OrderGrouper.new group_rules, column_properties
#        
#        line_items = @orders.map { |o| o.line_items }.flatten

#        subject.table(line_items).class.should == Array
#      end
#    end
    
#    context "when grouping by customers" do
#      group_rules = [ { group_by: Proc.new { |li| li.variant.product }, sort_by: Proc.new { |product| product.name } }, { group_by: Proc.new { |li| li.variant }, sort_by: Proc.new { |variant| variant.options_text } }, { group_by: Proc.new { |li| li.order.bill_address }, sort_by: Proc.new { |bill_address| bill_address.firstname + " " + bill_address.lastname } } ]
#      column_properties = [ Proc.new { |lis| lis.first.order.bill_address.firstname + " " + lis.first.order.bill_address.lastname },  Proc.new { |lis| lis.first.variant.product.name }, Proc.new { |lis| "UNIT SIZE" }, Proc.new { |lis| lis.first.variant.options_text }, Proc.new { |lis| lis.first.variant.weight }, Proc.new { |lis|  lis.sum { |li| li.quantity } }, Proc.new { |lis| lis.sum { |li| li.max_quantity || 0 } } ]     

#      it "should return a table as an array" do
#        subject = OrderGrouper.new group_rules, column_properties
        
#        line_items = @orders.map { |o| o.line_items }.flatten
        
#        subject.table(line_items).class.should == Array
#      end
#    end
#  end
#end

require 'spec_helper'

module OpenFoodWeb
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
      it "builds branches by removing a rule from \"rules\" and running group_and_sort" do
        rule1 = double(:rule1)
        rule2 = double(:rule2)
        rules = [rule1, rule2]
        column1 = double(:col1)
        column2 = double(:col2)
        columns = [column1, column2]

        subject = OrderGrouper.new rules, columns

        #rules = [ { group_by: Proc.new { |sentence| sentence.paragraph.chapter }, sort_by: Proc.new { |chapter| chapter.name }, summary_columns: [Proc.new { |is| is.first.paragraph.chapter.name }, Proc.new { |is| "TOTAL" }, Proc.new { |is| "" }, Proc.new { |is| is.sum {|i| i.property1 } } ] }, 
        #{ group_by: Proc.new { |sentence| sentence.paragraph }, sort_by: Proc.new { |paragraph| paragraph.name } } ]
        #columns = [Proc.new { |is| is.first.paragraph.chapter.name }, Proc.new { |is| is.first.paragraph.name }, Proc.new { |is| is.first.name }, Proc.new { |is| is.sum {|i| i.property1 } }]
        rules.should_receive(:clone).and_return(rules)
        rules.should_receive(:delete_at).with(0)
        grouped_tree = double(:grouped_tree)
        subject.should_receive(:group_and_sort).and_return(grouped_tree)

        subject.build_tree(@items, rules).should == grouped_tree
      end

      it "separates the first rule from rules before sending to group_and_sort" do
        rule1 = double(:rule1)
        rule2 = double(:rule2)
        rules = [rule1, rule2]
        column1 = double(:col1)
        column2 = double(:col2)
        columns = [column1, column2]

        subject = OrderGrouper.new rules, columns

        grouped_tree = double(:grouped_tree)
        subject.should_receive(:group_and_sort).with(rule1, rules[1..-1], @items).and_return(grouped_tree)

        subject.build_tree(@items, rules).should == grouped_tree
      end

      it "should group, then sort, send each group to build_tree, and return a branch" do
        rule1 = double(:rule1)
        rule2 = double(:rule2)
        rules = [rule1, rule2]
        remaining_rules = [rule2]
        column1 = double(:col1)
        column2 = double(:col2)
        columns = [column1, column2]

        summary_columns_object = double(:summary_columns)
        rule1.stub(:[]).with(:summary_columns) { summary_columns_object }

        subject = OrderGrouper.new rules, columns

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
        subject.group_and_sort(rule1, remaining_rules, @items).should == group_tree
      end
    end

    context "building the table Array" do
      it "should return columns when given an Array" do
        rule1 = double(:rule1)
        rule2 = double(:rule2)
        rules = [rule1, rule2]
        column1 = double(:col1)
        column2 = double(:col2)
        columns = [column1, column2]
        column1.stub(:call) { "Column1" }
        column2.stub(:call) { "Column2" }

        item1 = double(:item1)
        item2 = double(:item2)
        item3 = double(:item3)
        items1 = [item1, item2]
        items2 = [item2, item3]
        groups = { items1: items1, items2: items1 }

        subject = OrderGrouper.new rules, columns

        column1.should_receive(:call)
        column2.should_receive(:call)

        subject.build_table(items1).should == [["Column1", "Column2"]]
      end
      
      it "should return a row for each key-value pair when given a Hash" do
        rule1 = double(:rule1)
        rule2 = double(:rule2)
        rules = [rule1, rule2]
        column1 = double(:col1)
        column2 = double(:col2)
        columns = [column1, column2]
        column1.stub(:call) { "Column1" }
        column2.stub(:call) { "Column2" }

        item1 = double(:item1)
        item2 = double(:item2)
        item3 = double(:item3)
        items1 = [item1, item2]
        items2 = [item2, item3]
        items3 = [item3, item1]
        groups = { items1: items1, items2: items2, items3: items3 }

        subject = OrderGrouper.new rules, columns

        #subject.should_receive(:build_table).exactly(2).times

        expected_return = []
        groups.length.times { expected_return << ["Column1", "Column2"] }
        subject.build_table(groups).should == expected_return
      end

      it "should return an extra row when a :summary_row key appears in a given Hash" do
        rule1 = double(:rule1)
        rule2 = double(:rule2)
        rules = [rule1, rule2]
        column1 = double(:col1)
        column2 = double(:col2)
        columns = [column1, column2]
        column1.stub(:call) { "Column1" }
        column2.stub(:call) { "Column2" }

        sumcol1 = double(:sumcol1)
        sumcol2 = double(:sumcol2)
        sumcols = [sumcol1, sumcol2]
        sumcol1.stub(:call) { "SumColumn1" }
        sumcol2.stub(:call) { "SumColumn2" }

        item1 = double(:item1)
        item2 = double(:item2)
        item3 = double(:item3)
        items1 = [item1, item2]
        items2 = [item2, item3]
        items3 = [item3, item1]
        groups = { items1: items1, items2: items2, items3: items3, summary_row: { items: { items2: items2, items3: items3 }, columns: sumcols } }

        subject = OrderGrouper.new rules, columns

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