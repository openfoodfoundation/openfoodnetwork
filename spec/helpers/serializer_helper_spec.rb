# frozen_string_literal: true

RSpec.describe SerializerHelper do
  let(:serializer) do
    Class.new(ActiveModel::Serializer) do
      attributes :id, :name
    end
  end

  describe "#required_attributes" do
    it "returns only the attributes from the model that the serializer needs to be queried" do
      required_attributes = helper.required_attributes Enterprise, serializer

      expect(required_attributes).to eq ['enterprises.id', 'enterprises.name']
    end
  end
end
