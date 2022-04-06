# frozen_string_literal: true

module FilePreferences
  extend ActiveSupport::Concern

  included do
    @default_urls = {}
  end

  class_methods do
    def file_preference(name, default_url: nil)
      preference "#{name}_blob_id", :integer
      @default_urls[name] = default_url if default_url
    end

    def default_url(name)
      @default_urls[name]
    end
  end

  def preference_type(key)
    if has_preference?("#{key}_blob_id")
      :file
    else
      super(key)
    end
  end

  def url_for(name)
    blob = blob_for(name)

    if blob
      Rails.application.routes.url_helpers.url_for(blob)
    else
      self.class.default_url(name)
    end
  end

  def blob_for(name)
    blob_id = get_preference("#{name}_blob_id")
    ActiveStorage::Blob.find_by(id: blob_id) if blob_id
  end
end
