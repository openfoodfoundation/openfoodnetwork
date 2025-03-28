# frozen_string_literal: true

require 'active_support/concern'

module ProductStock
  extend ActiveSupport::Concern

  def on_hand
    variants.map(&:on_hand).reduce(:+)
  end
end
