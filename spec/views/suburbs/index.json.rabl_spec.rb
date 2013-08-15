require 'spec_helper'

describe 'suburbs/index.json.rabl' do
  before(:each) do
    Suburb.any_instance.stub(:state_name).and_return("Victoria")
    @suburb1 = Suburb.create(name: "Camberwell", postcode: 3124, latitude: -37.824818, longitude: 145.057957)
    @suburb2 = Suburb.create(name: "Hawthorn", postcode: 3122, latitude: -37.824830, longitude: 145.057950)
    @rendered = Rabl.render([@suburb1, @suburb2], 'suburbs/index', view_path: 'app/views')
  end

  it "should have an array of suburbs" do
    @rendered.should have_json_type(Array).at_path('')
  end

  it "should have 2 suburbs" do
    @rendered.should have_json_size(2).at_path('')
  end

  it "should include suburb ids and labels" do
    @rendered.should include_json("{\"id\": #{@suburb1.id}, \"label\": \"#{@suburb1.name} (#{@suburb1.state_name}), #{@suburb1.postcode}\"}")
  end
end
