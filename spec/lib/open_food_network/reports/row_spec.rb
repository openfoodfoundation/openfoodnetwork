require 'open_food_network/reports/row'

module OpenFoodNetwork::Reports
  describe Row do
    let(:row) { Row.new }
    let(:proc) { Proc.new {} }

    it "can define a number of columns and return them as an array" do
      row.column &proc
      row.column &proc
      row.column &proc

      row.to_a.should == [proc, proc, proc]
    end
  end
end
