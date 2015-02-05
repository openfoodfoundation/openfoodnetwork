require 'spec_helper'

describe GroupsHelper do
   describe "ext_url" do
     it "adds prefix if missing" do
       expect(helper.ext_url("http://example.com/", "http://example.com/bla")).to eq("http://example.com/bla")
       expect(helper.ext_url("http://example.com/", "bla")).to eq("http://example.com/bla")
     end
   end
   describe "strip_url" do
     it "removes http(s)://" do
       expect(helper.strip_url("http://example.com/")).to eq("example.com/")
       expect(helper.strip_url("https://example.com/")).to eq("example.com/")
       expect(helper.strip_url("example.com")).to eq("example.com")
     end
   end
   describe "link_to_url" do
     it "gives a link to an html external url" do
       expect(helper.link_to_url("example.com")).to eq('<a href="http://example.com" target="_blank">example.com</a>')
       expect(helper.link_to_url("https://example.com/")).to eq('<a href="https://example.com/" target="_blank">example.com/</a>')
     end
   end
end
