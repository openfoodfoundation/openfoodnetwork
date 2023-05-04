require 'aws-sdk-s3'

class PublicImages < ActiveRecord::Migration[7.0]
  def up
    return unless s3_bucket

    check_connection!
    set_objects_to_readable

    ActiveStorage::Blob.
      where(service_name: "amazon").
      where("content_type LIKE 'image/%'").
      update_all(service_name: "amazon_public")
  end

  def down
    ActiveStorage::Blob.
      where(service_name: "amazon_public").
      where("content_type LIKE 'image/%'").
      update_all(service_name: "amazon")
  end

  private

  # Returns an Aws::S3::Bucket object
  def s3_bucket
    @s3_bucket ||= ActiveStorage::Blob.where(service_name: "amazon").first&.service&.bucket
  end

  # Checks bucket status. Throws an error if connection fails
  def check_connection!
    s3_bucket.exists?
  end

  # Sets bucket objects' ACL to "public-read". Performs batched processing internally
  # with a custom enumerator, see AWS::Resources::Collection#each for details.
  def set_objects_to_readable
    s3_bucket.objects.each{|object| object.acl.put(acl: "public-read") }
  end
end
