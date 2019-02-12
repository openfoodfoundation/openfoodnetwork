module Reports
  module Parameters
    class Base
      extend ActiveModel::Naming
      extend ActiveModel::Translation
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks

      def initialize(attributes = {})
        attributes.each do |key, value|
          public_send("#{key}=", value)
        end
      end

      # The parameters are never persisted.
      def to_key; end
    end
  end
end
