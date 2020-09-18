# frozen_string_literal: true

require 'spec_helper'
require 'rake'

describe "images.rake" do
  let(:variant) { create(:variant) }
  let(:image_file) { File.open(Rails.root.join("app/assets/images/logo-white.png")) }

  before(:all) do
    Rake.application.rake_require 'tasks/images'
    Rake.application.rake_require 'tasks/paperclip'
    Rake::Task.define_task(:environment)
  end

  describe ":delete_orphans" do
    let(:subject) { Rake::Task["images:delete_orphans"] }

    it "reports the number of orphaned image entries" do
      Spree::Image.create!(
        attachment: image_file,
        viewable_id: variant.id,
        viewable_type: variant.class.name,
      )

      expect {
        subject.execute
      }.to output(/Found 0 out of 1 images could be deleted/).to_stdout
    end

    it "deletes orphaned image entries" do
      valid_image = Spree::Image.create!(
        attachment: image_file,
        viewable_id: variant.id,
        viewable_type: variant.class.name,
      )
      orphan = Spree::Image.create!(
        attachment: image_file,
        viewable_id: variant.id,
        viewable_type: variant.class.name,
      )
      orphan.update!(attachment_file_size: 0)

      expect(ENV).to receive(:fetch).with("DELETE_IMAGES", false).and_return("true")
      allow_any_instance_of(Object).to receive(:sleep)
      expect {
        expect {
          subject.execute
        }.to change { Spree::Image.count }.by(-1)
      }.to output(/Done\. 1 image records were deleted/).to_stdout
      expect(Spree::Image.pluck(:id)).to include valid_image.id
      expect(Spree::Image.pluck(:id)).to_not include orphan.id
    end
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

  describe ":regenerate_thumbnails" do
    let(:subject) { Rake::Task["images:regenerate_thumbnails"] }

    it "reprocesses all images" do
      2.times do
        Spree::Image.create!(
          attachment: image_file,
          viewable_id: variant.id,
          viewable_type: variant.class.name,
        )
      end

      attachment = double(Paperclip::Attachment)
      allow(Paperclip::Attachment).to receive(:new).and_return(attachment)
      expect(attachment).to receive(:reprocess!).with(:small).twice

      env = {
        "CLASS" => "Spree::Image",
        "STYLES" => "small",
      }
      stub_const("ENV", ENV.to_hash.merge(env))
      expect {
        subject.execute
      }.to output(/ done\./).to_stdout
    end
  end
end
