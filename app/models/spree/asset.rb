# frozen_string_literal: true

module Spree
  class Asset < ActiveRecord::Base
    belongs_to :viewable, polymorphic: true, touch: true
  end
end
