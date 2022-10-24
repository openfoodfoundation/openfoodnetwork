module DirtyModel
  extend ActiveSupport::Concern

  included do
    def save_dirty(cache_namespace: nil)
      Rails.cache.write(dirty_cache_key, self, namespace: cache_namespace)
    end

    def dirty_cache_key
      self.class.dirty_cache_key(id)
    end
  end

  class_methods do
    def dirty(id, cache_namespace: nil)
      Rails.cache.read(dirty_cache_key(id), namespace: cache_namespace)
    end

    def clear_dirty(id, cache_namespace: nil)
      Rails.cache.delete(dirty_cache_key(id), namespace: cache_namespace)
    end

    def dirty_cache_key(id)
      "dirty_#{self.model_name.singular}_#{id}"
    end
  end
end
