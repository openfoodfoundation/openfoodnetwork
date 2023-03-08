module Invoice::DataPresenterAttributes
  extend ActiveSupport::Concern

  def attributes(*attributes,prefix: nil)
    attributes.each do |attribute|
      define_method([prefix,attribute].reject(&:blank?).join("_")) do
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
                              Invoice::DataPresenter.const_get(attribute.to_s.classify).new(data&.[](attribute)))
      end
    end
  end

  def array_attribute(attribute_name,class_name: nil)
    define_method(attribute_name) do
      instance_variable = instance_variable_get("@#{attribute_name}")
      return instance_variable if instance_variable

      instance_variable_set("@#{attribute_name}",
                            data&.[](attribute_name)&.map { |item|
                              Invoice::DataPresenter.const_get(class_name).new(item)
                            })
    end
  end

  def relevant_attributes(*attributes)
    define_method(:relevant_values) do
      attributes.map do |attribute|
        send(attribute)
      end
    end
  end
end
