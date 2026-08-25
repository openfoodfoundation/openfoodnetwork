# frozen_string_literal: true

module OpenFoodNetwork
  module AddToParam
    def add_to_param(method)
      define_method(:to_param) do
        id = super()

        return if id.nil?

        slug = __send__(method).parameterize

        "#{id}-#{slug}"
      end
    end
  end
end
