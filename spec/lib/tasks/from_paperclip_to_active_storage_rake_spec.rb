# frozen_string_literal: true

require "spec_helper"
require "rake"

describe "from_paperclip_to_active_storage.rake" do
  include FileHelper

  let(:file) { Rack::Test::UploadedFile.new(black_logo_file, 'image/png') }
  let(:s3_config) {
    {
      url: ":s3_alias_url",
      storage: :s3,
      s3_credentials: {
        access_key_id: "A...A",
        secret_access_key: "H...H",
      },
      s3_headers: { "Cache-Control" => "max-age=31557600" },
      bucket: "ofn",
      s3_protocol: "https",
      s3_host_alias: "ofn.s3.us-east-1.amazonaws.com",

      # This is for easier testing:
      path: "/:id/:style/:basename.:extension",
    }
  }

  before(:all) do
    Rake.application.rake_require "tasks/from_paperclip_to_active_storage"
    Rake::Task.define_task(:environment)
  end

  describe ":migrate" do
    it "creates Active Storage records for existing images on disk" do |example|
      image = Spree::Image.create!(attachment: file)
      image.attachment_attachment.delete
      image.attachment_blob.delete

      expect {
        run_task "from_paperclip_to_active_storage:migrate"
      }.to change {
        image.reload.active_storage_attachment.attached?
      }.to(true)
    end

    it "creates Active Storage records for existing images on disk" do |example|
      attachment_definition = Spree::Image.attachment_definitions[:attachment]
      allow(Spree::Image).to receive(:attachment_definitions).and_return(
        attachment: attachment_definition.merge(s3_config)
      )
      allow(Rails.application.config.active_storage).
        to receive(:service).and_return(:test_amazon)

      stub_request(:put, /amazonaws/).to_return(status: 200, body: "", headers: {})
      stub_request(:head, /amazonaws/).to_return(
        status: 200, body: "",
        headers: {
          "ETag" => "md5sum000test000example"
        }
      )
      stub_request(:put, /amazonaws/).to_return(status: 200, body: "", headers: {})

      image = Spree::Image.create!(attachment: file)
      image.attachment_attachment.delete
      image.attachment_blob.delete

      expect {
        run_task "from_paperclip_to_active_storage:migrate"
      }.to change {
        image.reload.active_storage_attachment.attached?
      }.to(true)

      expect(image.attachment_blob.checksum).to eq "md5sum000test000example"
    end
  end

  def run_task(name)
    Rake::Task[name].reenable
    Rake.application.invoke_task(name)
  end
end
