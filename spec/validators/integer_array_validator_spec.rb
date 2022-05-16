# frozen_string_literal: true

require "spec_helper"

describe IntegerArrayValidator do
  class TestModel
    include ActiveModel::Validations

    attr_accessor :ids

    validates :ids, integer_array: true
  end

  describe "internationalization" do
    it "has translation for NOT_ARRAY_ERROR" do
      expect(described_class.not_array_error).not_to be_blank
    end

    it "has translation for INVALID_ELEMENT_ERROR" do
      expect(described_class.invalid_element_error).not_to be_blank
    end
  end

  describe "validation" do
    let(:instance) { TestModel.new }

    it "does not add error when nil" do
      instance.ids = nil
      expect(instance).to be_valid
    end

    it "does not add error when blank array" do
      instance.ids = []
      expect(instance).to be_valid
    end

    it "adds error NOT_ARRAY_ERROR when neither nil nor an array" do
      instance.ids = 1
      expect(instance).not_to be_valid
      expect(instance.errors[:ids]).to include(described_class.not_array_error)
    end

    it "does not add error when array of integers" do
      instance.ids = [1, 2, 3]
      expect(instance).to be_valid
    end

    it "does not add error when array of integers as String" do
      instance.ids = ["1", "2", "3"]
      expect(instance).to be_valid
    end

    it "adds error INVALID_ELEMENT_ERROR when an element cannot be parsed as Integer" do
      instance.ids = [1, "2", "Not Integer", 3]
      expect(instance).not_to be_valid
      expect(instance.errors[:ids]).to include(described_class.invalid_element_error)
    end
  end
end
