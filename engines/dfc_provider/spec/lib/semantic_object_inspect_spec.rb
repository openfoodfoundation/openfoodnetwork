# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe VirtualAssembly::Semantizer::SemanticObject do
  describe "#pretty_inspect" do
    it "provides a clean output for Address" do
      subject = DataFoodConsortium::Connector::Address.new("some/id")

      expect(subject.pretty_inspect).to match <<~HEREDOC
        #<DataFoodConsortium::Connector::Address:.*
         @semanticId="some/id",
         @semanticType="dfc-b:Address",
         @street=nil,
         @postalCode=nil,
         @city=nil,
         @country=nil,
         @latitude=nil,
         @longitude=nil,
         @region=nil>
      HEREDOC
    end

    it "provides a clean output for OrderLine" do
      subject = DataFoodConsortium::Connector::OrderLine.new("some/id")

      expect(subject.pretty_inspect).to match <<~HEREDOC
        #<DataFoodConsortium::Connector::OrderLine:.*
         @semanticId="some/id",
         @semanticType="dfc-b:OrderLine",
         @description=nil,
         @quantity=nil,
         @price=nil,
         @offer=nil,
         @order=nil>
      HEREDOC
    end
  end
end
