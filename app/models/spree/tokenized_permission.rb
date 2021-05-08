# frozen_string_literal: true

module Spree
  class TokenizedPermission < ApplicationRecord
    belongs_to :permissable, polymorphic: true
  end
end
