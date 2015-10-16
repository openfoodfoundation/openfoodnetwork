require 'open_food_network/reports/rule'

module OpenFoodNetwork::Reports
  describe Rule do
    let(:rule) { Rule.new }
    let(:proc) { Proc.new {} }

    it "can define a group proc and return it in a hash" do
      rule.group &proc
      rule.to_h.should == {group_by: proc, sort_by: nil}
    end

    it "can define a sort proc and return it in a hash" do
      rule.sort &proc
      rule.to_h.should == {group_by: nil,  sort_by: proc}
    end

    it "can define a nested rule" do
      rule.organise &proc
      rule.next.should be_a Rule
    end

    it "can define a summary row and return it in a hash" do
      rule.summary_row do
        column {}
        column {}
        column {}
      end

      rule.to_h[:summary_columns].count.should == 3
      rule.to_h[:summary_columns][0].should be_a Proc
      rule.to_h[:summary_columns][1].should be_a Proc
      rule.to_h[:summary_columns][2].should be_a Proc
    end
  end
end
