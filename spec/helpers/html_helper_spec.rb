require 'spec_helper'

describe HtmlHelper do
  describe "stripping html from a string" do
    it "strips tags" do
      helper.strip_html('<p><b>Hello</b> <em>world</em>!</p>').should == 'Hello world!'
    end

    it "removes nbsp and amp entities" do
      helper.strip_html('Hello&nbsp;world&amp;&amp;').should == 'Hello world&&'
    end

    it "returns nil for nil input" do
      helper.strip_html(nil).should be_nil
    end
  end
end
