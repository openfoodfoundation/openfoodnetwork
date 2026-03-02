# frozen_string_literal: true


require_relative '../../db/migrate/20241023054951_sanitize_html_attributes'

RSpec.describe SanitizeHtmlAttributes do
  describe "#up" do
    # Let's hack some bad data:
    let!(:tab) {
      create(:custom_tab).tap do |row|
        row.update_columns(content: bad_html)
      end
    }
    let!(:enterprise_group) {
      create(:enterprise_group).tap do |row|
        row.update_columns(long_description: bad_html)
      end
    }
    let!(:product) {
      create(:product).tap do |row|
        row.update_columns(description: bad_html)
      end
    }
    let(:bad_html) {
      <<~HTML.squish
        <p data-controller="load->payMe">Fred Farmer is a certified
        <a href="https://example.net/">organic</a>
        <script>alert("Gotcha!")</script>...</p>
      HTML
    }
    let(:good_html) {
      <<~HTML.squish
        <p>Fred Farmer is a certified
        <a href="https://example.net/">organic</a>
        alert("Gotcha!")...</p>
      HTML
    }
    let(:good_html_external_link) {
      <<~HTML.squish
        <p>Fred Farmer is a certified
        <a href="https://example.net/" target="_blank">organic</a>
        alert("Gotcha!")...</p>
      HTML
    }

    it "sanitises HTML attributes" do
      expect { subject.up }.to change {
        tab.reload.attributes["content"]
      }
        .from(bad_html).to(good_html)
        .and change {
               enterprise_group.reload.attributes["long_description"]
             }
        .from(bad_html).to(good_html_external_link)
        .and change {
               product.reload.attributes["description"]
             }
        .from(bad_html).to(good_html)
    end
  end
end
