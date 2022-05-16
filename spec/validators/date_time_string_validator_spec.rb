# frozen_string_literal: true

require "spec_helper"

describe DateTimeStringValidator do
  class TestModel
    include ActiveModel::Validations

    attr_accessor :timestamp

    validates :timestamp, date_time_string: true
  end

  describe "internationalization" do
    it "has translation for NOT_STRING_ERROR" do
      expect(described_class.not_string_error).not_to be_blank
    end

    it "has translation for INVALID_FORMAT_ERROR" do
      expect(described_class.invalid_format_error).not_to be_blank
    end
  end

  describe "validation" do
    let(:instance) { TestModel.new }

    it "does not add error when nil" do
      instance.timestamp = nil
      expect(instance).to be_valid
    end

    it "does not add error when blank string" do
      instance.timestamp = nil
      expect(instance).to be_valid
    end

    it "adds error NOT_STRING_ERROR when blank but neither nil nor a string" do
      instance.timestamp = []
      expect(instance).not_to be_valid
      expect(instance.errors[:timestamp]).to eq([described_class.not_string_error])
    end

    it "adds error NOT_STRING_ERROR when not a string" do
      instance.timestamp = 1
      expect(instance).not_to be_valid
      expect(instance.errors[:timestamp]).to eq([described_class.not_string_error])
    end

    it "does not add error when value can be parsed" do
      instance.timestamp = "2018-09-20 01:02:00 +10:00"
      expect(instance).to be_valid
    end

    it "adds error INVALID_FORMAT_ERROR when value cannot be parsed" do
      instance.timestamp = "Not Valid"
      expect(instance).not_to be_valid
      expect(instance.errors[:timestamp]).to eq([described_class.invalid_format_error])
    end
  end
end
