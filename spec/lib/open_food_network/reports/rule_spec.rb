require 'spec_helper'
require 'open_food_network/reports/rule'

module OpenFoodNetwork::Reports
  describe Rule do
    let(:rule) { Rule.new }
    # rubocop:disable Style/Proc
    let(:proc) { Proc.new {} }
    # rubocop:enable Style/Proc

    it "can define a group proc and return it in a hash" do
      rule.group(&proc)
      expect(rule.to_h).to eq(group_by: proc, sort_by: nil)
    end

    it "can define a sort proc and return it in a hash" do
      rule.sort(&proc)
      expect(rule.to_h).to eq(group_by: nil, sort_by: proc)
    end
  end
end
