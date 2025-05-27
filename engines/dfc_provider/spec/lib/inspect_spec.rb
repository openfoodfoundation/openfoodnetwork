# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "#inspect" do
  it "provides a clean-enough output for Address" do
    subject = DataFoodConsortium::Connector::Address.new("some/id")

    expect(subject.inspect).to eq <<~HEREDOC.squish
      #<DataFoodConsortium::Connector::Address
      {"semanticId"=>"some/id", "semanticType"=>"dfc-b:Address", "street"=>nil, "postalCode"=>nil,
      "city"=>nil, "country"=>nil, "latitude"=>nil, "longitude"=>nil, "region"=>nil}>
    HEREDOC
  end

  it "provides a clean-enough output for OrderLine" do
    subject = DataFoodConsortium::Connector::OrderLine.new("some/id")

    expect(subject.inspect).to eq <<~HEREDOC.squish
      #<DataFoodConsortium::Connector::OrderLine
      {"semanticId"=>"some/id", "semanticType"=>"dfc-b:OrderLine", "description"=>nil,
      "quantity"=>nil, "price"=>nil, "offer"=>nil, "order"=>nil}>
    HEREDOC
  end
end
