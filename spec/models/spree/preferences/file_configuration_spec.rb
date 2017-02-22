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
          c.get_preference(:name).should == 'foo'
        end

        it "returns file preferences" do
          c.get_preference(:logo).should be_a Paperclip::Attachment
        end

        it "returns regular preferences via []" do
          c.name = 'foo'
          c[:name].should == 'foo'
        end

        it "returns file preferences via []" do
          c[:logo].should be_a Paperclip::Attachment
        end
      end

      describe "getting preference types" do
        it "returns regular preference types" do
          c.preference_type(:name).should == :string
        end

        it "returns file preference types" do
          c.preference_type(:logo).should == :file
        end
      end

      describe "respond_to?" do
        it "responds to preference getters" do
          c.respond_to?(:name).should be true
        end

        it "responds to preference setters" do
          c.respond_to?(:name=).should be true
        end
      end
    end
  end
end
