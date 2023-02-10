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
      {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: data_properties(**options)
          },
          meta: { type: :object },
          links: { type: :object }
        },
        required: [:data]
      }
    end

    def collection(options)
      {
        type: :object,
        properties: {
          data: {
            type: :array,
            items: {
              type: :object,
              properties: data_properties(**options)
            }
          },
          meta: {
            type: :object,
            properties: {
              pagination: {
                type: :object,
                properties: {
                  results: { type: :integer, example: 250 },
                  pages: { type: :integer, example: 5 },
                  page: { type: :integer, example: 2 },
                  per_page: { type: :integer, example: 50 },
                }
              }
            },
            required: [:pagination]
          },
          links: {
            type: :object,
            properties: {
              self: { type: :string },
              first: { type: :string },
              prev: { type: :string, nullable: true },
              next: { type: :string, nullable: true },
              last: { type: :string }
            }
          }
        },
        required: [:data, :meta, :links]
      }
    end

    private

    def data_properties(require_all: false, extra_fields: nil)
      extra_fields_result = get_extra_fields(extra_fields)
      attributes = get_attributes(extra_fields_result)
      required = get_required(require_all, extra_fields, extra_fields_result)

      {
        id: { type: :string, example: "1" },
        type: { type: :string, example: object_name },
        attributes: {
          type: :object,
          properties: attributes,
          required: required
        },
        relationships: {
          type: :object,
          properties: relationships.to_h do |name|
            [
              name,
              relationship_schema(name)
            ]
          end
        }
      }
    end

    # Example
    # extra_fields: :my_method
    # => extra_fields_result = my_method
    # => attributes = attributes.merge(extra_fields_result)
    #
    # extra_fields: {name: :my_method, required: true, opts: {method_opt: true}}
    # => extra_fields_result = my_method({method_opt: true})
    # => attributes = attributes.merge(extra_fields_result)
    # => required += extra_fields_result.keys
    #
    # extra_fields: [:my_method, :another_method]
    # => extra_fields_result = my_method.merge(another_method)
    # => attributes = attribtues.merge(extra_fields_result)
    #
    # To test use eg::
    # => MySchema.collection(..., extra_fields: ...)
    #     .dig(:properties, :data, :items, :properties, :attributes)
    def get_extra_fields(extra_fields)
      case extra_fields
      when Symbol
        public_send(extra_fields)
      when Hash
        extra_fields[:opts] &&
          public_send(extra_fields[:name], extra_fields[:opts]) || public_send(extra_fields[:name])
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
