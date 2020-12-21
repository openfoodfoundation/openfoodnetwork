# frozen_string_literal: true

module Spree
  class TokenizedPermission < ActiveRecord::Base
    belongs_to :permissable, polymorphic: true
  end
end
