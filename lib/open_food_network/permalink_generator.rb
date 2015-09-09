module PermalinkGenerator
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
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

  def create_unique_permalink(requested)
    existing = self.class.where('id != ?', id).where("permalink LIKE ?", "#{requested}%").pluck(:permalink)
    self.class.find_available_value(existing, requested)
  end
end
