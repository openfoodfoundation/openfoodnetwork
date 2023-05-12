# frozen_string_literal: true

require 'spec_helper'

describe Spree::LocalizedNumber do
  describe ".parse" do
    context "with point separator" do
      it "captures the proper amount for a formatted string" do
        expect(described_class.parse('5.67')).to eql 5.67
      end
    end

    context "with comma separator" do
      it "captures the proper amount for a formatted string" do
        expect(described_class.parse('5,67')).to eql 5.67
      end
    end

    context "with decimal point" do
      it "captures the proper amount for a formatted string" do
        expect(described_class.parse('1,599.99')).to eql 1599.99
      end
    end

    context "with decimal comma" do
      it "captures the proper amount for a formatted string" do
        expect(described_class.parse('1.599,99')).to eql 1599.99
      end
    end

    context "with a numeric input" do
      it "uses the amount as is" do
        expect(described_class.parse(1599.99)).to eql 1599.99
      end
    end

    context "with a string having 2 digits between separators" do
      it "ignores the left separator" do
        expect(described_class.parse('1,59.99')).to eql 159.99
      end
    end
  end

  describe ".valid_localizable_number?" do
    context "with a properly formatted string" do
      it "returns true" do
        expect(described_class.valid_localizable_number?('1.599,99')).to eql true
      end
    end

    context "with a string having 2 digits between separators" do
      it "returns false" do
        expect(described_class.valid_localizable_number?('1,59.99')).to eql false
      end
    end

    context "with a numeric input" do
      it "returns true" do
        expect(described_class.valid_localizable_number?(1599.99)).to eql true
      end

      context "with a negative number" do
        it "returns true" do
          expect(described_class.valid_localizable_number?(-1599.99)).to eql true
        end
      end
    end

    context "with letters" do
      it "returns false" do
        expect(described_class.valid_localizable_number?('invalid')).to eql false
      end
    end
  end
end
