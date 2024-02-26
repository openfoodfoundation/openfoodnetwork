# frozen_string_literal: true

require "system_helper"

describe "proof of concept puffing", :billy do
  context "visiting OFN homepage" do
    it "redirects to another page" do
      proxy.stub("http://127.0.0.1").and_return(text: "I'm not OFN!")
      visit "http://127.0.0.1"
      expect(page).to have_content("I'm not OFN!")
    end
  end
end
