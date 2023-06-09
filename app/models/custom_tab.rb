# frozen_string_literal: false

class CustomTab < ApplicationRecord
  belongs_to :enterprise, optional: false

  validates :title, presence: true, length: { maximum: 20 }
end
