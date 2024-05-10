# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HtmlSanitizer do
  subject { described_class }

  it "removes dangerous tags" do
    html = "Hello <script>alert</script>!"
    expect(subject.sanitize(html))
      .to eq "Hello alert!"
  end

  it "keeps supported tags" do
    html = "Hello <b>alert</b>!"
    expect(subject.sanitize(html))
      .to eq "Hello <b>alert</b>!"
  end

  it "keeps supported attributes" do
    html = 'Hello <a href="#focus">alert</a>!'
    expect(subject.sanitize(html))
      .to eq 'Hello <a href="#focus">alert</a>!'
  end

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
end
