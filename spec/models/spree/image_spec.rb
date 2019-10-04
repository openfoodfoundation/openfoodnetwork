require 'spec_helper'

module Spree
  describe Image do
    describe "attachment definitions" do
      let(:name_str)  { { "mini" => "48x48>" } }
      let(:formatted) { { mini: ["48x48>", "png"] } }

      it "converts style names to symbols" do
        expect(Image.format_styles(name_str)).to eq(mini: "48x48>")
      end

      it "converts formats to symbols" do
        expect(Image.format_styles(formatted)).to eq(mini: ["48x48>", :png])
      end
    end
  end
end
