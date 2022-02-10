# frozen_string_literal: true

# Finds a unique permalink for a new or updated record.
# It considers soft-deleted records which are ignored by Spree.
# Spree's work:
# https://github.com/spree/spree/blob/09b55f7/core/lib/spree/core/permalinks.rb
#
# This may become obsolete with Spree 2.3.
# https://github.com/spree/spree/commits/master/core/lib/spree/core/permalinks.rb
module PermalinkGenerator
  extend ActiveSupport::Concern

  class_methods do
    def find_available_value(existing, requested)
      return requested unless existing.include?(requested)

      used_indices = existing.map do |p|
        p.slice!(/^#{requested}/)
        p.match(/^\d+$/).to_s.to_i
      end
      options = (1..used_indices.length + 1).to_a - used_indices
      requested + options.first.to_s
    end
  end

  private

  def create_unique_permalink(requested)
    existing = others.where("permalink LIKE ?", "#{requested}%").pluck(:permalink)
    self.class.find_available_value(existing, requested)
  end

  def others
    if id.nil?
      scope_with_deleted
    else
      scope_with_deleted.where('id != ?', id)
    end
  end

  def scope_with_deleted
    if self.class.respond_to?(:with_deleted)
      self.class.with_deleted
    else
      self.class.where(nil)
    end
  end
end
