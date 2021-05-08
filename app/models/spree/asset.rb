# frozen_string_literal: true

module Spree
  class Asset < ApplicationRecord
    belongs_to :viewable, polymorphic: true, touch: true
    acts_as_list scope: :viewable
  end
end
