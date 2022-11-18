# frozen_string_literal: true

class BatchTaggableTagsQuery
  def self.call(taggables)
    ::ActsAsTaggableOn::Tag.
      joins(:taggings).
      includes(:taggings).
      where(taggings:
        {
          taggable_type: taggables.model.to_s,
          taggable_id: taggables,
          context: 'tags'
        }).order("tags.name").each_with_object({}) do |tag, indexed_hash|
      tag.taggings.each do |tagging|
        indexed_hash[tagging.taggable_id] ||= []
        indexed_hash[tagging.taggable_id] << tag.name
      end
    end
  end
end
