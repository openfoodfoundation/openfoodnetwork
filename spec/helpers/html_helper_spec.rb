require 'spec_helper'

describe HtmlHelper do
  describe "stripping html from a string" do
    it "strips tags" do
      helper.strip_html('<p><b>Hello</b> <em>world</em>!</p>').should == "Hello world!\n"
    end

    it "removes nbsp and amp entities" do
      helper.strip_html('Hello&nbsp;world&amp;&amp;').should == 'Hello world&&'
    end

    it "returns nil for nil input" do
      helper.strip_html(nil).should be_nil
    end

    describe "line breaks" do
      it "adds a line break after heading tags" do
        helper.strip_html("<h1>foo</h1>").should == "foo\n";
        helper.strip_html("<h2>foo</h2>").should == "foo\n";
      end

      it "adds a line break after br tags" do
        helper.strip_html("foo<br>").should == "foo\n";
        helper.strip_html("foo<br/>").should == "foo\n";
        helper.strip_html("foo<br />").should == "foo\n";
      end

      it "adds a line break after p tags" do
        helper.strip_html("<p>foo</p>").should == "foo\n";
      end

      it "adds a line break after div tags" do
        helper.strip_html("<div>foo</div>").should == "foo\n";
      end

      it "squeezes multiple line breaks" do
        helper.strip_html("<p>foo</p><br /><br>bar").should == "foo\nbar";
      end
    end
  end
end
