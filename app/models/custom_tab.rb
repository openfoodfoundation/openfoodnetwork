# frozen_string_literal: false

class CustomTab < ApplicationRecord
  belongs_to :enterprise

  validates :title, presence: true, length: { maximum: 20 }
end
