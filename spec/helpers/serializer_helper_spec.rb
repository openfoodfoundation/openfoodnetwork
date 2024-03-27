# frozen_string_literal: true

require 'spec_helper'

class ExampleEnterpriseSerializer < ActiveModel::Serializer
  attributes :id, :name
end

describe SerializerHelper, type: :helper do
  let(:serializer) { ExampleEnterpriseSerializer }

  describe "#required_attributes" do
    it "returns only the attributes from the model that the serializer needs to be queried" do
      required_attributes = helper.required_attributes Enterprise, serializer

      expect(required_attributes).to eq ['enterprises.id', 'enterprises.name']
    end
  end
end
