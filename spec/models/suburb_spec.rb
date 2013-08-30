require 'spec_helper'

describe Suburb do
  it { should belong_to(:state) }
  it { should delegate(:name).to(:state).with_prefix }

  describe "searching for matching suburbs" do
    before(:each) do
      Suburb.create(name: "Camberwell", postcode: 3124, latitude: -37.824818, longitude: 145.057957, state_id: Spree::State.first)
    end

    it "should find suburb on part of name" do
      Suburb.matching("Camb").count.should be > 0
    end

    it "should find suburb on part of postcode" do
      Suburb.matching(312).count.should be > 0
    end

    it "should find nothing where part doesn't match" do
      Suburb.matching("blahblah1234#!!!").count.should_not be > 0
    end
  end
end
