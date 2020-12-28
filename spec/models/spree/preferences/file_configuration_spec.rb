# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Preferences
    class TestConfiguration < FileConfiguration
      preference :name, :string

      include OpenFoodNetwork::Paperclippable
      preference :logo, :file
      has_attached_file :logo
    end

    describe FileConfiguration do
      let(:c) { TestConfiguration.new }

      describe "getting preferences" do
        it "returns regular preferences" do
          c.name = 'foo'
          expect(c.get_preference(:name)).to eq('foo')
        end

        it "returns file preferences" do
          expect(c.get_preference(:logo)).to be_a Paperclip::Attachment
        end

        it "returns regular preferences via []" do
          c.name = 'foo'
          expect(c[:name]).to eq('foo')
        end

        it "returns file preferences via []" do
          expect(c[:logo]).to be_a Paperclip::Attachment
        end
      end

      describe "getting preference types" do
        it "returns regular preference types" do
          expect(c.preference_type(:name)).to eq(:string)
        end

        it "returns file preference types" do
          expect(c.preference_type(:logo)).to eq(:file)
        end
      end

      describe "respond_to?" do
        it "responds to preference getters" do
          expect(c.respond_to?(:name)).to be true
        end

        it "responds to preference setters" do
          expect(c.respond_to?(:name=)).to be true
        end
      end
    end
  end
end
