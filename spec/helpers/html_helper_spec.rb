require 'spec_helper'

describe HtmlHelper do
  class HelperStub
    extend ActionView::Helpers::SanitizeHelper::ClassMethods
    include ActionView::Helpers::SanitizeHelper
  end

  subject do
    obj = HelperStub.new
    obj.extend HtmlHelper
  end

  describe "stripping html from a string" do
    it "strips tags" do
      subject.strip_html('<p><b>Hello</b> <em>world</em>!</p>').should == 'Hello world!'
    end

    it "removes nbsp and amp entities" do
      subject.strip_html('Hello&nbsp;world&amp;&amp;').should == 'Hello world&&'
    end

    it "returns nil for nil input" do
      subject.strip_html(nil).should be_nil
    end
  end
end
