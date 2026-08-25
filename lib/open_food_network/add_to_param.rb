# frozen_string_literal: true

module OpenFoodNetwork
  module AddToParam
    def add_to_param(method)
      define_method(:to_param) do
        slug = __send__(method).parameterize

        "#{super()}-#{slug}"
      end
    end
  end
end
