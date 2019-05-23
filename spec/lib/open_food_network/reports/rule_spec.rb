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

    it "can define a nested rule" do
      rule.organise(&proc)
      expect(rule.next).to be_a Rule
    end

    it "can define a summary row and return it in a hash" do
      rule.summary_row do
        column {}
        column {}
        column {}
      end

      expect(rule.to_h[:summary_columns].count).to eq(3)
      expect(rule.to_h[:summary_columns][0]).to be_a Proc
      expect(rule.to_h[:summary_columns][1]).to be_a Proc
      expect(rule.to_h[:summary_columns][2]).to be_a Proc
    end
  end
end
