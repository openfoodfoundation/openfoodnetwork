# frozen_string_literal: true

require "open_food_network/add_to_param"

RSpec.describe OpenFoodNetwork::AddToParam do
  let(:model) {
    Class.new(Spree::Product) do
      extend OpenFoodNetwork::AddToParam

      def self.name
        "Spree::Product"
      end
    end
  }

  it "adds text to #to_param" do
    expect {
      model.add_to_param(:name)
    }.to change {
      model.new(id: 1, name: "Apples: Golden Delicious").to_param
    }.from("1").to("1-apples-golden-delicious")
  end

  it "creates a param that #find can use as id" do
    model.add_to_param(:name)

    apple = model.create!(name: "Apple", price: 1)
    found = model.find(apple.to_param)

    expect(found).to eq apple
  end
end
