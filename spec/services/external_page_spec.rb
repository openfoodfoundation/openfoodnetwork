# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalPage do
  subject(:page) { described_class.new(html, "https://cms.example.com/home/") }

  let(:html) do
    <<~HTML
      <html>
        <head>
          <style id="wp-block-columns-inline-css">.wp-block-columns{display:flex}</style>
          <style id="global-styles-inline-css">:root{--wp--preset--color--black:#000}</style>
          <style id="divi-style-inline-inline-css">body{line-height:1}</style>
          <link rel="stylesheet" href="https://cms.example.com/wp-includes/blocks/cover/style.css">
          <link rel="stylesheet" href="https://cms.example.com/wp-content/plugins/cookies.css">
        </head>
        <body>
          <div class="entry-content is-layout-constrained">
            <p>Hello</p>
            <a href="/shops">Shops</a>
            <img src="../uploads/tomato.jpg" onerror="alert(1)">
            <script>alert("hi")</script>
          </div>
        </body>
      </html>
    HTML
  end

  describe "#content" do
    it "keeps the content wrapper and its classes" do
      expect(page.content).to start_with '<div class="entry-content is-layout-constrained">'
      expect(page.content).to include "<p>Hello</p>"
    end

    it "removes scripts and event handlers" do
      expect(page.content).not_to include "script"
      expect(page.content).not_to include "onerror"
    end

    it "resolves relative URLs against the source page" do
      expect(page.content).to include 'href="https://cms.example.com/shops"'
      expect(page.content).to include 'src="https://cms.example.com/uploads/tomato.jpg"'
    end

    it "keeps URLs it can't resolve" do
      page = described_class.new(
        '<div class="entry-content"><a href="http://foo bar">Broken link</a></div>',
        "https://cms.example.com/home/"
      )

      expect(page.content).to include "Broken link"
      expect(page.content).to include "foo bar"
    end

    it "falls back to the body when there's no content wrapper" do
      page = described_class.new("<html><body><p>Hi</p></body></html>", "https://cms.example.com")

      expect(page.content.strip).to eq "<p>Hi</p>"
    end
  end

  describe "#styles" do
    it "keeps the styles of the block editor" do
      expect(page.styles).to include ".wp-block-columns{display:flex}"
      expect(page.styles).to include "--wp--preset--color--black"
      expect(page.styles).to include "/wp-includes/blocks/cover/style.css"
    end

    it "ignores theme and plugin styles which would affect our own layout" do
      expect(page.styles).not_to include "line-height:1"
      expect(page.styles).not_to include "cookies.css"
    end
  end

  describe ".fetch" do
    it "reads the given page" do
      stub_request(:get, "https://cms.example.com/home/").to_return(body: html)

      expect(described_class.fetch("https://cms.example.com/home/").content).to include "Hello"
    end

    it "raises on an error response" do
      stub_request(:get, "https://cms.example.com/home/").to_return(status: 500)

      expect { described_class.fetch("https://cms.example.com/home/") }.
        to raise_error Faraday::ServerError
    end
  end
end
