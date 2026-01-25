# frozen_string_literal: true

RSpec.describe ApplicationRecord do
  describe ".image_service" do
    subject { described_class.image_service }

    it { is_expected.to eq(:local) }

    context "with a S3 bucket defined" do
      before do
        allow(ENV).to receive(:[]).with("S3_BUCKET").and_return("test-bucket")
        allow(ENV).to receive(:[]).with("S3_ENDPOINT").and_return(nil)
      end

      it { is_expected.to eq(:amazon_public) }

      context "with a S3 endpoint defined" do
        before do
          allow(ENV).to receive(:[]).with("S3_ENDPOINT")
            .and_return("https://s3-compatible-alternative.com")
        end

        it { is_expected.to eq(:s3_compatible_storage_public) }
      end
    end
  end
end
