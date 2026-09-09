# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'External home page' do
  let(:url) { "https://cms.example.com/home/" }
  let(:html) do
    <<~HTML
      <html>
        <head>
          <style id="wp-block-tab-panel-inline-css">
            .wp-block-tab-panel[hidden] { display: none !important }
          </style>
        </head>
        <body>
          <div class="entry-content">
            <p>Buy local food</p>
            <div class="wp-block-tabs">
              <div class="wp-block-tab-list" role="tablist">
                <button type="button" role="tab" aria-controls="panel-1">Melbourne</button>
                <button type="button" role="tab" aria-controls="panel-2">Sydney</button>
              </div>
              <div class="wp-block-tab-panels">
                <section hidden role="tabpanel" id="panel-1" class="wp-block-tab-panel">
                  <p>A hub in Melbourne</p>
                </section>
                <section hidden role="tabpanel" id="panel-2" class="wp-block-tab-panel">
                  <p>A hub in Sydney</p>
                </section>
              </div>
            </div>
          </div>
        </body>
      </html>
    HTML
  end

  before do
    Rails.cache.clear
    ContentConfig.home_page_url = url
    stub_request(:get, url).to_return(body: html)
    ExternalPageJob.perform_now
  end

  it "renders the content within our own layout" do
    visit root_path

    expect(page).to have_content "Buy local food"
    expect(page).to have_selector "nav.top-bar"
    expect(page).to have_selector "#footer"
  end

  # WordPress renders all tab panels hidden and reveals the active one with its
  # own JavaScript, which we don't load. See WpTabsController.
  it "shows one tab panel at a time" do
    visit root_path

    expect(page).to have_content "A hub in Melbourne"
    expect(page).not_to have_content "A hub in Sydney"

    click_on "Sydney"

    expect(page).to have_content "A hub in Sydney"
    expect(page).not_to have_content "A hub in Melbourne"
  end
end
