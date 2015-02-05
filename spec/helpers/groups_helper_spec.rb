require 'spec_helper'

describe GroupsHelper do
   describe "ext_url" do
     it "adds http:// if missing" do
       expect(helper.ext_url("http://example.com/")).to eq("http://example.com/")
       expect(helper.ext_url("https://example.com/")).to eq("https://example.com/")
       expect(helper.ext_url("example.com")).to eq("http://example.com")
     end
   end
   describe "strip_url" do
     it "removes http(s)://" do
       expect(helper.strip_url("http://example.com/")).to eq("example.com/")
       expect(helper.strip_url("https://example.com/")).to eq("example.com/")
       expect(helper.strip_url("example.com")).to eq("example.com")
     end
   end
   describe "link_to_ext" do
     it "gives a link to an html external url" do
       expect(helper.link_to_ext("example.com")).to eq('<a href="http://example.com" target="_blank">example.com</a>')
       expect(helper.link_to_ext("https://example.com/")).to eq('<a href="https://example.com/" target="_blank">example.com/</a>')
     end
   end
end
