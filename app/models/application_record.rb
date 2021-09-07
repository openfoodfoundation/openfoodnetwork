# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include DelegateBelongsTo
  include Spree::Core::Permalinks
  include Spree::Preferences::Preferable
  include Searchable

  self.abstract_class = true
end
