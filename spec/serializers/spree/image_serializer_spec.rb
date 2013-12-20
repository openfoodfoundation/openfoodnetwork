require 'spec_helper'

describe Spree::ImageSerializer do
  it "should give us the small url" do
    image = Spree::Image.new(attachment: double(:attachment))
    image.attachment.should_receive(:url).with(:small, false)
    Spree::ImageSerializer.new(image).to_json
  end
end
