# frozen_string_literal: true

RSpec.describe UploadSanitizer do
  describe "#call" do
    let(:upload) do
      File.open("/tmp/unsanitized.csv", 'wb:ascii-8bit') do |f|
        f << "\xEF\xBB\xBF"
        f << "Test"
      end
    end
    let(:service) { UploadSanitizer.new(File.read(upload)) }

    it "sanitizes the uploaded file" do
      sanitized_upload = service.call

      expect(sanitized_upload.encoding.name).to eq "UTF-8"
      expect(sanitized_upload.to_s).to eq "Test"
    end
  end
end
