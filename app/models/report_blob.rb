# frozen_string_literal: true

# Stores a generated report.
class ReportBlob < ActiveStorage::Blob
  # AWS S3 limits URL expiry to one week.
  LIFETIME = 1.week

  def self.create_locally!(filename, content)
    create_and_upload!(
      io: StringIO.new(content),
      filename:,
      content_type: content_type(filename),
      identify: false,
      service_name: :local,
    )
  end

  def self.create_for_upload_later!(filename)
    # ActiveStorage discourages modifying a blob later but we need a blob
    # before we know anything about the report file. It enables us to use the
    # same blob in the controller to read the result.
    create_before_direct_upload!(
      filename:,
      byte_size: 0,
      checksum: "0",
      content_type: content_type(filename),
      service_name: :local,
    ).tap do |blob|
      ActiveStorage::PurgeJob.set(wait: LIFETIME).perform_later(blob)
    end
  end

  def self.content_type(filename)
    MIME::Types.of(filename).first&.to_s || "application/octet-stream"
  end

  def store(content)
    io = StringIO.new(content)
    upload(io, identify: false)
    save!
  end

  def result
    return if checksum == "0"

    @result ||= download.force_encoding(Encoding::UTF_8)
  end

  def expiring_service_url
    url(expires_in: LIFETIME)
  end
end
