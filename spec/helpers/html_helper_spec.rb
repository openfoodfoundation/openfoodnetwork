require 'spec_helper'

describe HtmlHelper, type: :helper do
  describe "stripping html from a string" do
    it "strips tags" do
      helper.strip_html('<p><b>Hello</b> <em>world</em>!</p>').should == "Hello world!"
    end

    it "removes nbsp and amp entities" do
      helper.strip_html('Hello&nbsp;world&amp;&amp;').should == 'Hello world&&'
    end

    it "returns nil for nil input" do
      helper.strip_html(nil).should be_nil
    end

    describe "line breaks" do
      it "adds two line breaks after heading tags" do
        helper.strip_html("<h1>foo</h1>bar").should == "foo\n\nbar";
        helper.strip_html("<h2>foo</h2>bar").should == "foo\n\nbar";
      end

      it "adds two line breaks after p tags" do
        helper.strip_html("<p>foo</p>bar").should == "foo\n\nbar";
      end

      it "adds two line breaks after div tags" do
        helper.strip_html("<div>foo</div>bar").should == "foo\n\nbar";
      end

      it "adds a line break after br tags" do
        helper.strip_html("foo<br>bar").should == "foo\nbar";
        helper.strip_html("foo<br/>bar").should == "foo\nbar";
        helper.strip_html("foo<br />bar").should == "foo\nbar";
      end

      it "strips line breaks at the end of the string" do
        helper.strip_html("<div>foo</div><br />").should == "foo";
      end
    end
  end
end
