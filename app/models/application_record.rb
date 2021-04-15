# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include DelegateBelongsTo

  self.abstract_class = true
end
