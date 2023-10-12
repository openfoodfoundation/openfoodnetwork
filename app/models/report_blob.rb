# frozen_string_literal: true

# Stores a generated report.
class ReportBlob < ActiveStorage::Blob
  # AWS S3 limits URL expiry to one week.
  LIFETIME = 1.week

  def self.create!(filename, content)
    create_and_upload!(
      io: StringIO.new(content),
      filename:,
      content_type: content_type(filename),
      identify: false,
      service_name: :local,
    )
  end

  def self.content_type(filename)
    MIME::Types.of(filename).first&.to_s || "application/octet-stream"
  end

  def result
    @result ||= download.force_encoding(Encoding::UTF_8)
  end

  def expiring_service_url
    url(expires_in: LIFETIME)
  end
end
