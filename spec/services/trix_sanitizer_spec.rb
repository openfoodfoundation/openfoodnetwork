# frozen_string_literal: true

RSpec.describe TrixSanitizer do
  let(:service) { described_class.new }

  describe "#sanitize_content" do
    it "returns nil for blank content" do
      expect(service.sanitize_content(nil)).to be_nil
      expect(service.sanitize_content("")).to be_nil
    end

    it "preserves content without leading empty blocks" do
      html = "<div>Real product description.</div>"
      expect(service.sanitize_content(html)).to include("Real product description.")
    end

    it "strips a leading empty block" do
      html = "<div><br></div><div>Real product description.</div>"
      result = service.sanitize_content(html)
      expect(result).to include("Real product description.")
      expect(result).not_to match(%r{<div>\s*<br\s*/?>\s*</div>\s*<div>})
    end

    it "strips multiple leading empty blocks" do
      html = "<div><br></div><div><br></div><div>Real product description.</div>"
      result = service.sanitize_content(html)
      expect(result).to include("Real product description.")
      expect(result).not_to start_with("<div><br>")
    end

    it "strips a leading <br> before text inside an inline element" do
      html = "<div><em><br>Helianthus tuberosus</em> is a plant.</div>"
      result = service.sanitize_content(html)
      expect(result).to include("Helianthus tuberosus")
      expect(result).not_to match(%r{<em>\s*<br\s*/?>\s*Helianthus})
    end

    it "strips a leading <br> directly before text in a block" do
      html = "<div><br>Product description text.</div>"
      result = service.sanitize_content(html)
      expect(result).to include("Product description text.")
      expect(result).not_to match(%r{<div>\s*<br\s*/?>\s*Product})
    end

    it "preserves a leading block that contains an image" do
      html = %(<div><img src="photo.jpg" alt="product"></div><div>Description.</div>)
      result = service.sanitize_content(html)
      expect(result).to include("photo.jpg")
      expect(result).to include("Description.")
    end

    it "preserves empty blocks and <br> that are not at the start" do
      html = "<div>First paragraph.</div><div><br></div><div>Second paragraph.</div>"
      result = service.sanitize_content(html)
      expect(result).to include("First paragraph.")
      expect(result).to include("Second paragraph.")
    end

    it "removes disallowed tags" do
      html = "<div><script>alert('xss')</script>Safe content.</div>"
      expect(service.sanitize_content(html)).not_to include("<script>")
    end
  end
end
