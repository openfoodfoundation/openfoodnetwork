# frozen_string_literal: true

class JsonApiSchema
  class << self
    def attributes
      {}
    end

    def required_attributes
      []
    end

    def relationships
      []
    end

    def all_attributes
      attributes.keys
    end

    def schema(options = {})
      Structure.schema(data_properties(**options))
    end

    def collection(options)
      Structure.collection(data_properties(**options))
    end

    private

    def data_properties(require_all: false, extra_fields: nil)
      extra_fields_result = get_extra_fields(extra_fields)
      attributes = get_attributes(extra_fields_result)
      required = get_required(require_all, extra_fields, extra_fields_result)

      Structure.data_properties(object_name, attributes, required, relationship_properties)
    end

    def relationship_properties
      relationships.index_with { |name| relationship_schema(name) }
    end

    # Example
    # MySchema.schema(extra_fields: :my_method)
    # => extra_fields_result = MySchema.my_method
    # => attributes = attributes.merge(extra_fields_result)
    #
    # MySchema.schema(extra_fields: {name: :my_method, required: true, opts: {method_opt: true}})
    # => extra_fields_result = MySchema.my_method(method_opt: true)
    # => attributes = attributes.merge(extra_fields_result)
    # => required += extra_fields_result.keys
    #
    # MySchema.schema(extra_fields: [:my_method, :another_method])
    # => extra_fields_result = MySchema.my_method.merge(another_method)
    # => attributes = attribtues.merge(extra_fields_result)
    #
    # To test use eg:
    # MySchema.schema(extra_fields: :my_method)
    #   .dig(:properties, :data, :properties, :attributes)
    def get_extra_fields(extra_fields)
      case extra_fields
      when Symbol
        public_send(extra_fields)
      when Hash
        public_send(extra_fields[:name], **extra_fields[:opts].to_h)
      when Array
        obj = {}

        extra_fields.each do |w|
          obj.merge!(get_extra_fields(w))
        end

        obj
      end
    end

    def get_required(require_all, extra_fields, extra_fields_result)
      required = require_all ? all_attributes : required_attributes

      if extra_fields.is_a?(Hash) && extra_fields[:required] == true && extra_fields_result.present?
        required += extra_fields_result.keys
      end

      required
    end

    def get_attributes(extra_fields_result)
      if [extra_fields_result, attributes].all?{ |obj| obj.respond_to?(:merge) }
        attributes.merge(extra_fields_result)
      else
        attributes
      end
    end

    def relationship_schema(name)
      if is_singular?(name)
        RelationshipSchema.schema(name)
      else
        RelationshipSchema.collection(name)
      end
    end

    def is_singular?(name)
      name.to_s.singularize == name.to_s
    end
  end
end
