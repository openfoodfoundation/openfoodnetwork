# frozen_string_literal: true

RSpec.describe HtmlSanitizer do
  subject { described_class }

  context "when HTML has supported tags" do
    it "keeps supported regular tags" do
      supported_tags = %w[h1 h2 h3 h4 div p b i u a strong em del pre blockquote ul ol li figure]
      supported_tags.each do |tag|
        html = "<#{tag}>Content</#{tag}>"
        sanitized_html = subject.sanitize(html)
        expect(sanitized_html).to eq(html), "Expected '#{tag}' to be preserved."
      end
    end

    it "keeps supported void tags" do
      supported_tags = %w[br hr]
      supported_tags.each do |tag|
        html = "<#{tag}>"
        sanitized_html = subject.sanitize(html)
        expect(sanitized_html).to eq(html), "Expected '#{tag}' to be preserved."
      end
    end

    it "handles nested tags" do
      html = '<div><ul><li>Item 1</li><li><strong>Item 2</strong></li></ul></div>'
      expect(subject.sanitize(html)).to eq(html)
    end
  end

  context "when HTML has dangerous tags" do
    it "removes script tags" do
      html = "Hello <script>alert</script>!"
      expect(subject.sanitize(html)).to eq "Hello alert!"
    end

    it "removes iframe tags" do
      html = "Content <iframe src='http://malicious-site.com'></iframe>"
      expect(subject.sanitize(html)).to eq "Content "
    end

    it "removes object tags" do
      html = "<object data='malicious-file.swf'></object>"
      expect(subject.sanitize(html)).to eq ""
    end

    it "removes embed tags" do
      html = "<embed src='malicious-video.mp4' type='video/mp4'>"
      expect(subject.sanitize(html)).to eq ""
    end

    it "removes link tags" do
      html = "<link rel='stylesheet' href='http://malicious-site.com/style.css'>"
      expect(subject.sanitize(html)).to eq ""
    end

    it "removes base tags" do
      html = "<base href='http://phishing-site.com/'>"
      expect(subject.sanitize(html)).to eq ""
    end

    it "removes form tags" do
      html = "<form action='http://malicious-site.com/submit' method='post'>...</form>"
      expect(subject.sanitize(html)).to eq "..."
    end

    it "removes combined dangerous tags" do
      html = "<script>alert</script><iframe scr='http://malicious-site.com'></iframe>"
      expect(subject.sanitize(html)).to eq "alert"
    end
  end

  context "when HTML has supported attributes" do
    it "keeps supported attributes" do
      html = 'Hello <a href="#focus">alert</a>!'
      expect(subject.sanitize(html))
        .to eq 'Hello <a href="#focus">alert</a>!'
    end
  end

  context "when HTML has dangerous attributes" do
    it "removes unsupported attributes" do
      html = 'Hello <a href="#focus" onclick="alert">alert</a>!'
      expect(subject.sanitize(html))
        .to eq 'Hello <a href="#focus">alert</a>!'
    end

    it "removes dangerous attribute values" do
      html = 'Hello <a href="javascript:alert(\"boo!\")">you</a>!'
      expect(subject.sanitize(html))
        .to eq 'Hello <a>you</a>!'
    end

    it "keeps only Trix-specific data attributes" do
      html = '<figure data-trix-attachment="{...}" data-script="">...</figure>'
      expect(subject.sanitize(html)).to eq('<figure data-trix-attachment="{...}">...</figure>')
    end
  end

  context "when HTML has leading whitespace" do
    it "preserves content without leading empty blocks" do
      html = "<div>Real product description.</div>"
      expect(subject.sanitize(html)).to include("Real product description.")
    end

    it "strips a leading empty block" do
      html = "<div><br></div><div>Real product description.</div>"
      result = subject.sanitize(html)
      expect(result).to include("Real product description.")
      expect(result).not_to match(%r{<div>\s*<br\s*/?>\s*</div>\s*<div>})
    end

    it "strips multiple leading empty blocks" do
      html = "<div><br></div><div><br></div><div>Real product description.</div>"
      result = subject.sanitize(html)
      expect(result).to include("Real product description.")
      expect(result).not_to start_with("<div><br>")
    end

    it "strips a leading <br> before text inside an inline element" do
      html = "<div><em><br>Helianthus tuberosus</em> is a plant.</div>"
      result = subject.sanitize(html)
      expect(result).to include("Helianthus tuberosus")
      expect(result).not_to match(%r{<em>\s*<br\s*/?>\s*Helianthus})
    end

    it "strips a leading <br> inside an inline wrapper that precedes text" do
      html = "<div><em><br></em>Real text.</div>"
      result = subject.sanitize(html)
      expect(result).to include("Real text.")
      expect(result).not_to match(%r{<br\s*/?>})
    end

    it "strips a leading <br> directly before text in a block" do
      html = "<div><br>Product description text.</div>"
      result = subject.sanitize(html)
      expect(result).to include("Product description text.")
      expect(result).not_to match(%r{<div>\s*<br\s*/?>\s*Product})
    end

    it "preserves empty blocks and <br> that are not at the start" do
      html = "<div>First paragraph.</div><div><br></div><div>Second paragraph.</div>"
      result = subject.sanitize(html)
      expect(result).to include("First paragraph.")
      expect(result).to include("Second paragraph.")
    end

    it "preserves a standalone void element with no other content" do
      expect(subject.sanitize("<br>")).to eq("<br>")
      expect(subject.sanitize("<hr>")).to eq("<hr>")
    end

    it "preserves a leading void element followed by real content" do
      html = "<hr><div>Real text</div>"
      expect(subject.sanitize(html)).to eq(html)
    end
  end

  context "when HTML has links" do
    describe "#sanitize" do
      it "doesn't add target blank to links" do
        html = '<a href="https://example.com">Link</a>'
        expect(subject.sanitize(html)).to eq('<a href="https://example.com">Link</a>')
      end
    end

    describe "#sanitize_and_enforece_link_target_blank" do
      it "adds target blank to links so they open in new windows" do
        html = '<a href="https://example.com">Link</a>'
        expect(subject.sanitize_and_enforce_link_target_blank(html))
          .to eq('<a href="https://example.com" target="_blank">Link</a>')
      end
    end
  end
end
