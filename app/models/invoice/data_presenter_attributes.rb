# frozen_string_literal: true

class Invoice
  module DataPresenterAttributes
    extend ActiveSupport::Concern

    def attributes(*attributes, prefix: nil)
      attributes.each do |attribute|
        define_method([prefix, attribute].compact_blank.join("_")) do
          data&.[](attribute)
        end
      end
    end

    def attributes_with_presenter(*attributes)
      attributes.each do |attribute|
        define_method(attribute) do
          instance_variable = instance_variable_get("@#{attribute}")
          return instance_variable if instance_variable

          instance_variable_set("@#{attribute}",
                                Invoice::DataPresenter.const_get(
                                  attribute.to_s.classify
                                ).new(data&.[](attribute)))
        end
      end
    end

    def array_attribute(attribute_name, class_name: nil)
      define_method(attribute_name) do
        instance_variable = instance_variable_get("@#{attribute_name}")
        return instance_variable if instance_variable

        instance_variable_set("@#{attribute_name}",
                              data&.[](attribute_name)&.map { |item|
                                Invoice::DataPresenter.const_get(class_name).new(item)
                              })
      end
    end

    # if one of the list attributes is updated, the invoice needs to be regenerated
    def invoice_generation_attributes(*attributes)
      define_method(:invoice_generation_values) do
        attributes.map do |attribute|
          public_send(attribute)
        end
      end
    end

    # if one of the list attributes is updated, the invoice needs to be updated
    def invoice_update_attributes(*attributes)
      define_method(:invoice_update_values) do
        attributes.map do |attribute|
          public_send(attribute)
        end
      end
    end
  end
end
