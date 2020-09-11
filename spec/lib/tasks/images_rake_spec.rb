# frozen_string_literal: true

require 'spec_helper'
require 'rake'

describe "images.rake" do
  before(:all) do
    Rake.application.rake_require 'tasks/images'
    Rake.application.rake_require 'tasks/paperclip'
    Rake::Task.define_task(:environment)
  end

  describe ":reset_styles" do
    let(:subject) { Rake::Task["images:reset_styles"] }

    it "parses and sets given image styles" do
      env = {
        "CLASS" => "Spree::Image",
        "STYLE_DEFS" => '{"small":["227x227#","jpg"]}',
      }
      stub_const("ENV", ENV.to_hash.merge(env))

      subject.execute

      expect(Spree::Image.attachment_definitions[:attachment][:styles]).to eq(
        small: ["227x227#", :jpg]
      )
    end
  end
end
