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

    describe "callbacks" do
      let!(:product)    { create(:simple_product) }

      let!(:image_file) { File.open("#{Rails.root}/app/assets/images/logo-white.png") }
      let!(:image)      { Image.create(viewable_id: product.master.id, viewable_type: 'Spree::Variant', alt: "image", attachment: image_file) }

      it "refreshes the products cache when changed" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        image.alt = 'asdf'
        image.save
      end

      it "refreshes the products cache when destroyed" do
        expect(OpenFoodNetwork::ProductsCache).to receive(:product_changed).with(product)
        image.destroy
      end
    end
  end
end
