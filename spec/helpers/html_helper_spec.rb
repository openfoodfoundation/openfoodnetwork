require 'spec_helper'

describe HtmlHelper, type: :helper do
  describe "stripping html from a string" do
    it "strips tags" do
      expect(helper.strip_html('<p><b>Hello</b> <em>world</em>!</p>')).to eq("Hello world!")
    end

    it "removes nbsp and amp entities" do
      expect(helper.strip_html('Hello&nbsp;world&amp;&amp;')).to eq('Hello world&&')
    end

    it "returns nil for nil input" do
      expect(helper.strip_html(nil)).to be_nil
    end

    describe "line breaks" do
      it "adds two line breaks after heading tags" do
        expect(helper.strip_html("<h1>foo</h1>bar")).to eq("foo\n\nbar");
        expect(helper.strip_html("<h2>foo</h2>bar")).to eq("foo\n\nbar");
      end

      it "adds two line breaks after p tags" do
        expect(helper.strip_html("<p>foo</p>bar")).to eq("foo\n\nbar");
      end

      it "adds two line breaks after div tags" do
        expect(helper.strip_html("<div>foo</div>bar")).to eq("foo\n\nbar");
      end

      it "adds a line break after br tags" do
        expect(helper.strip_html("foo<br>bar")).to eq("foo\nbar");
        expect(helper.strip_html("foo<br/>bar")).to eq("foo\nbar");
        expect(helper.strip_html("foo<br />bar")).to eq("foo\nbar");
      end

      it "strips line breaks at the end of the string" do
        expect(helper.strip_html("<div>foo</div><br />")).to eq("foo");
      end
    end
  end
end
