require 'spec_helper'

module Spree
  describe Image do
    describe "attachment definitions" do
      let(:name_str)  { {"mini" => "48x48>"} }
      let(:formatted) { {mini: ["48x48>", "png"]} }

      it "converts style names to symbols" do
        Image.format_styles(name_str).should == {:mini => "48x48>"}
      end

      it "converts formats to symbols" do
        Image.format_styles(formatted).should == {:mini => ["48x48>", :png]}
      end
    end
  end
end
