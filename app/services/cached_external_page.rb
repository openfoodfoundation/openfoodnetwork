# frozen_string_literal: true

# Serves an external page from the cache only, so that a page load never waits
# for another server to respond.
#
# The cache is filled in the background by ExternalPageJob: on a schedule and,
# as a fallback, whenever we notice that our copy is missing or getting old.
# We cache without expiry so that we can keep serving the last known version
# when the CMS is unreachable.
class CachedExternalPage
  REFRESH_AFTER = 15.minutes
  # Only one refresh per URL within this time, no matter how many page loads
  # notice that the content is stale.
  REFRESH_LOCK_EXPIRY = 1.minute

  # Returns a hash of `content`, `styles` and `fetched_at`, or nil when we
  # don't have a copy yet.
  def self.fetch(url)
    return if url.blank?

    page = Rails.cache.read(cache_key(url))
    request_refresh(url) if page.nil? || stale?(page)
    page
  end

  def self.refresh(url)
    page = ExternalPage.fetch(url)
    raise "No content found at #{url}" if page.content.blank?

    Rails.cache.write(
      cache_key(url),
      { content: page.content, styles: page.styles, fetched_at: Time.zone.now }
    )
  end

  def self.request_refresh(url)
    return unless refresh_lock(url)

    ExternalPageJob.perform_later(url)
  end

  # Returns false if another process claimed the refresh already.
  def self.refresh_lock(url)
    Rails.cache.write(
      "#{cache_key(url)}/refreshing", true,
      unless_exist: true, expires_in: REFRESH_LOCK_EXPIRY
    )
  end

  def self.stale?(page)
    page[:fetched_at] < REFRESH_AFTER.ago
  end

  def self.cache_key(url)
    "external_page/#{Digest::SHA256.hexdigest(url)}"
  end

  private_class_method :request_refresh, :refresh_lock, :stale?, :cache_key
end
