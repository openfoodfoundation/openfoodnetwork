# frozen_string_literal: true

RSpec.describe Api::OpenStreetMapConfigSerializer do
  subject(:serializer) { described_class.new({}) }

  it "fits the map to enterprises by default" do
    expect(serializer.as_json).to include(
      open_street_map_fit_to_enterprises: true,
      open_street_map_default_zoom: 6
    )
  end

  it "serializes the configured initial view" do
    ContentConfig.open_street_map_fit_to_enterprises = false
    ContentConfig.open_street_map_default_zoom = 4

    expect(serializer.as_json).to include(
      open_street_map_fit_to_enterprises: false,
      open_street_map_default_zoom: 4
    )
  end
end
