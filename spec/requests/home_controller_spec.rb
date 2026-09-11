# frozen_string_literal: true

RSpec.describe HomeController do
  describe "#index" do
    it "renders the built-in home page" do
      get root_path

      expect(response.body).to include "tagline"
    end

    context "with an external home page configured" do
      let(:url) { "https://cms.example.com/home/" }

      before do
        Rails.cache.clear
        ContentConfig.home_page_url = url
      end

      it "renders the built-in page until the content is available" do
        get root_path

        expect(response.body).to include "tagline"
        expect(ExternalPageJob).to have_been_enqueued.with(url)
      end

      it "renders the external content within our layout" do
        stub_request(:get, url).to_return(
          body: <<~HTML
            <html>
              <head><style id="wp-block-columns-inline-css">.wp-block-columns{}</style></head>
              <body><div class="entry-content"><h1>Marketplace</h1></div></body>
            </html>
          HTML
        )
        ExternalPageJob.perform_now

        get root_path

        expect(response.body).to include "<h1>Marketplace</h1>"
        expect(response.body).to include ".wp-block-columns{}"
        expect(response.body).not_to include "tagline"
        expect(response.body).to include "ofn-logo-footer" # our own layout
      end
    end
  end

  context "#unauthorized" do
    it "renders the unauthorized template" do
      get "/unauthorized"

      expect(response).to have_http_status :unauthorized
      expect(response).to render_template("shared/unauthorized", layout: 'darkswarm')
    end
  end
end
