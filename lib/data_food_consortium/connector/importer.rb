# frozen_string_literal: true

require_relative "skos_parser"

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
          # Methods with variable arguments have a negative arity of -n-1
          # where n is the number of required arguments.
          number_of_required_args = -1 * (clazz.instance_method(:initialize).arity + 1)
          args = Array.new(number_of_required_args)
          type_uri = clazz.new(*args).semanticType
          result[type_uri] = clazz

          # Add support for the old DFC v1.7 URLs:
          new_type_uri = type_uri.gsub(
            "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_BusinessOntology.owl#",
            "http://static.datafoodconsortium.org/ontologies/DFC_BusinessOntology.owl#"
          )
          result[new_type_uri] = clazz
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
        # Not all subjects have an id, some are anonymous.
        id = type_statement.subject.try(:value)
        type = type_statement.object.value
        clazz = self.class.type_map[type]

        clazz.new(*[id].compact)
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

        # Backwards-compatibility with old DFC v1.7 ids:
        unless subject.hasSemanticProperty?(property_id)
          property_id = property_id.gsub(
            "http://static.datafoodconsortium.org/ontologies/DFC_BusinessOntology.owl#",
            "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_BusinessOntology.owl#"
          )
        end
        return unless subject.hasSemanticProperty?(property_id)

        property = subject.semanticProperty(property_id)

        if property.value.is_a?(Enumerable)
          property.value << value
        else
          setter = guess_setter_name(statement.predicate)
          subject.try(setter, value) if setter
        end
      end

      def subject_of(statement)
        @subjects[statement.subject]
      end

      def resolve_object(object)
        @subjects[object] || skos_concept(object) || object.object
      end

      def skos_concept(object)
        return unless object.uri?

        id = object.value.sub(
          "http://static.datafoodconsortium.org/data/measures.rdf#", "dfc-m:"
        ).sub(
          "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/measures.rdf#",
          "dfc-m:"
        )
        SKOSParser.concepts[id]
      end

      def guess_setter_name(predicate)
        fragment = predicate.fragment

        # Some predicates are named like `hasQuantity`
        # but the attribute name would be `quantity`.
        name = fragment.sub(/^has/, "").camelize(:lower)

        "#{name}="
      end
    end
  end
end
