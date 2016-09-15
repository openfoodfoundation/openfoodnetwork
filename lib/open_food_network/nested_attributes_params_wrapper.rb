module OpenFoodNetwork
  module NestAttributesParamsWrapper
    model_klass = controller_path.classify

    nested_attributes_names = StandingOrder.nested_attributes_options.keys.map { |k| k.to_s.concat('_attributes').to_sym }
    wrap_parameters include: StandingOrder.attribute_names + nested_attributes_names, format: :json
  end
end
