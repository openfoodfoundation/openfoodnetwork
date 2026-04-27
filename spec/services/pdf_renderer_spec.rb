# frozen_string_literal: true

RSpec.describe PdfRenderer do
  describe "#render" do
    it "wraps HTML fragments in a complete document" do
      expect(FerrumPdf).to receive(:render_pdf)
        .with(
          html: include("<!DOCTYPE html>", "<body>", "<h1>Invoice</h1>", "</body>"),
          display_url: "http://test.host/"
        )

      described_class.new.render("<h1>Invoice</h1>", display_url: "http://test.host/")
    end

    it "passes complete HTML documents through unchanged" do
      html = "<!DOCTYPE html><html><body>Report</body></html>"

      expect(FerrumPdf).to receive(:render_pdf)
        .with(html:, display_url: "http://test.host/")

      described_class.new.render(html, display_url: "http://test.host/")
    end
  end
end
