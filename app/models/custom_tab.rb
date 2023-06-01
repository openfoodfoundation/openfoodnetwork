# frozen_string_literal: false

class CustomTab < ApplicationRecord
  belongs_to :enterprise, optional: false
end
