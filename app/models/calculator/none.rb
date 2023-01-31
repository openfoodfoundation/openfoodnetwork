# frozen_string_literal: false

module Calculator
  class None < Spree::Calculator
    def self.description
      I18n.t(:none)
    end

    def compute(_object = nil)
      0
    end
  end
end
