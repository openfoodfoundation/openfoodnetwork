# frozen_string_literal: false

class CustomTab < ApplicationRecord
  belongs_to :enterprise, optional: false

  validates :title, presence: true
end
