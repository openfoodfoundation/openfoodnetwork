# frozen_string_literal: false

class CustomTab < ApplicationRecord
  self.belongs_to_required_by_default = true

  belongs_to :enterprise

  validates :title, presence: true, length: { maximum: 20 }
end
