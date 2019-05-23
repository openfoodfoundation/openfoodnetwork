require 'spec_helper'
require 'open_food_network/reports/row'

module OpenFoodNetwork::Reports
  describe Row do
    let(:row) { Row.new }
    # rubocop:disable Style/Proc
    let(:proc) { Proc.new {} }
    # rubocop:enable Style/Proc

    it "can define a number of columns and return them as an array" do
      row.column(&proc)
      row.column(&proc)
      row.column(&proc)

      expect(row.to_a).to eq([proc, proc, proc])
    end
  end
end
