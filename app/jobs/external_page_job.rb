# frozen_string_literal: true

# Keeps our copy of the CMS content up to date.
#
# It runs on a schedule, see config/sidekiq_scheduler.yml, and on demand when a
# page load finds no cached content.
class ExternalPageJob < ApplicationJob
  def perform(url = ContentConfig.home_page_url)
    return if url.blank?

    CachedExternalPage.refresh(url)
  rescue StandardError => e
    # We keep serving the previously cached content. There's no point in
    # retrying immediately, the next scheduled run will try again.
    Bugsnag.notify(e)
  end
end
