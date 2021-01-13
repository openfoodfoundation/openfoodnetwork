# frozen_string_literal: true

module OpenFoodNetwork
  class NullFeature
    def enabled?(_user)
      false
    end
  end
end
