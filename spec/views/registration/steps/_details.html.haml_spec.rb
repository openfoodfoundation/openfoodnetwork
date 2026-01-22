# frozen_string_literal: true

RSpec.describe "registration/steps/_details.html.haml" do
  subject { render }

  it "uses Google Maps when it is enabled" do
    allow(view).to receive_messages(using_google_maps?: true)

    is_expected.to match /<ui-gmap-google-map center='map.center' zoom='map.zoom'>/
  end

  it "uses OpenStreetMap when it is enabled" do
    ContentConfig.open_street_map_enabled = true
    allow(view).to receive_messages(using_google_maps?: false)

    is_expected.to match /<div class='map-container--registration' id='open-street-map'>/
  end
end
