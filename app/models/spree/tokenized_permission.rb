# frozen_string_literal: true

module Spree
  class TokenizedPermission < ApplicationRecord
    self.belongs_to_required_by_default = false

    belongs_to :permissable, polymorphic: true
  end
end
