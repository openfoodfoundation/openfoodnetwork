# frozen_string_literal: true

require "open_food_network/add_to_param"

RSpec.describe OpenFoodNetwork::AddToParam do
  let(:model) {
    Class.new(ApplicationRecord) do
      extend OpenFoodNetwork::AddToParam

      def self.name
        "Spree::Product"
      end

      def name
        "Apples: Golden Delicious"
      end
    end
  }

  it "adds text to #to_param" do
    expect {
      model.add_to_param(:name)
    }.to change {
      model.new(id: 1).to_param
    }.from("1").to("1-apples-golden-delicious")
  end

  it "creates a param that #find can use as id" do
    model.add_to_param(:name)

    apple = model.create!
    found = model.find(apple.to_param)

    expect(found).to eq apple
  end

  it "handles unpersisted records" do
    model.add_to_param(:name)

    expect(model.new.to_param).to eq nil
    expect(model.new(id: " ").to_param).to eq nil
  end
end
