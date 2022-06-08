# When migrating to Active Storage, we used Amazon's ETag for the blob
# checksum. But big files have been uploaded in chunks and then the checksum
# differs. We need to recalculate the checksum for large files.
class ComputeChecksumForBigFiles < ActiveRecord::Migration[6.1]
  def up
    blobs_with_incorrect_checksum.find_each do |blob|
      md5 = Digest::MD5.base64digest(blob.download)
      blob.update(checksum: md5)
    end
  end

  def blobs_with_incorrect_checksum
    ActiveStorage::Blob.
      where(service_name: "amazon").
      where("byte_size >= 20000000")
  end
end
