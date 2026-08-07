# frozen_string_literal: true

RSpec.describe "Google Fonts loading" do
  shared_examples "a page with the v2 Google Fonts link" do
    it "adds preconnect hints before a v2 Google Fonts URL including Open Sans, with no Roboto" do
      head_links = response.parsed_body.at("head").css("link")

      preconnect_links = head_links.select { |link| link["rel"] == "preconnect" }
      expect(preconnect_links.pluck("href")).to contain_exactly(
        "https://fonts.googleapis.com", "https://fonts.gstatic.com"
      )
      gstatic_preconnect = preconnect_links.find { |link| link["href"] == "https://fonts.gstatic.com" }
      expect(gstatic_preconnect["crossorigin"]).to eq ""

      stylesheet_link = head_links.find { |link|
        link["href"].to_s.include?("fonts.googleapis.com/css")
      }
      expect(stylesheet_link["href"]).to start_with("https://fonts.googleapis.com/css2?family=")
      expect(stylesheet_link["href"]).to include("Open+Sans")
      expect(stylesheet_link["href"]).to include("display=optional")
      expect(stylesheet_link["href"]).not_to include("Roboto")

      expect(head_links.index(stylesheet_link)).to be > head_links.index(preconnect_links.first)
      expect(head_links.index(stylesheet_link)).to be > head_links.index(preconnect_links.last)
    end
  end

  context "on a darkswarm-layout page" do
    before { get "/" }

    it_behaves_like "a page with the v2 Google Fonts link"
  end

  context "on a registration-layout page" do
    before { get "/register/auth" }

    it_behaves_like "a page with the v2 Google Fonts link"
  end
end
