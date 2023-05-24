# frozen_string_literal: true

module DataFoodConsortium
  module Connector
    class Importer
      TYPES = [
        DataFoodConsortium::Connector::CatalogItem,
        DataFoodConsortium::Connector::Enterprise,
        DataFoodConsortium::Connector::Offer,
        DataFoodConsortium::Connector::Person,
        DataFoodConsortium::Connector::QuantitativeValue,
        DataFoodConsortium::Connector::SuppliedProduct,
      ].freeze

      def self.type_map
        @type_map ||= TYPES.each_with_object({}) do |clazz, result|
          type_uri = clazz.new(nil).semanticType
          result[type_uri] = clazz
        end
      end

      def import(json_string_or_io)
        @subjects = {}

        graph = parse_rdf(json_string_or_io)
        build_subjects(graph)
        apply_statements(graph)

        if @subjects.size > 1
          @subjects.values
        else
          @subjects.values.first
        end
      end

      private

      # The `io` parameter can be a String or an IO instance.
      def parse_rdf(io)
        io = StringIO.new(io) if io.is_a?(String)
        RDF::Graph.new << JSON::LD::API.toRdf(io)
      end

      def build_subjects(graph)
        graph.query({ predicate: RDF.type }).each do |statement|
          @subjects[statement.subject] = build_subject(statement)
        end
      end

      def build_subject(type_statement)
        id = type_statement.subject.value
        type = type_statement.object.value
        clazz = self.class.type_map[type]

        clazz.new(id)
      end

      def apply_statements(statements)
        statements.each do |statement|
          apply_statement(statement)
        end
      end

      def apply_statement(statement)
        subject = subject_of(statement)
        property_id = statement.predicate.value
        value = resolve_object(statement.object)

        return unless subject.hasSemanticProperty?(property_id)

        property = subject.__send__(:findSemanticProperty, property_id)

        # Some properties have a one-to-one match to the method name.
        setter_name = "#{statement.predicate.fragment}="

        if property.value.is_a?(Enumerable)
          property.value << value
        elsif subject.respond_to?(setter_name)
          subject.public_send(setter_name, value)
        end
      end

      def subject_of(statement)
        @subjects[statement.subject]
      end

      def resolve_object(object)
        @subjects[object] || object.object
      end
    end
  end
end
