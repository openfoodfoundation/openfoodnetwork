# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Testing external scripts loaded in the browser" do
  before do
    skip "Puffing Billy seems to make our rspec processes hang at the end."
  end

  it "loads a website", :vcr do
    visit "http://deb.debian.org:80/debian/"
    expect(page).to have_content "Debian Archive"
  end

  it "handles HTTPS", :vcr do
    visit "https://deb.debian.org:443/debian/"
    expect(page).to have_content "Debian Archive"
  end

  it "stubs content" do
    stub_request(:get, "https://deb.debian.org:443").to_return(body: "stubbed")
    visit "https://deb.debian.org:443"
    expect(page).to have_content "stubbed"
  end
end
