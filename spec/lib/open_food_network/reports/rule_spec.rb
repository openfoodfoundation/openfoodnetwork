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
  end
end
