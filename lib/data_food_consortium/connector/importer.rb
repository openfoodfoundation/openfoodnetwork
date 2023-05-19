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

      def import(json_string)
        graph = parse_rdf(json_string)
        head, *tail = graph.to_a
        subject = build_subject(head)
        apply_statements(subject, tail)
        subject
      end

      private

      def parse_rdf(json_string)
        json_file = StringIO.new(json_string)
        RDF::Graph.new << JSON::LD::API.toRdf(json_file)
      end

      def build_subject(type_statement)
        id = type_statement.subject.value
        type = type_statement.object.value
        clazz = self.class.type_map[type]

        clazz.new(id)
      end

      def apply_statements(subject, statements)
        statements.each do |statement|
          apply_statement(subject, statement)
        end
      end

      def apply_statement(subject, statement)
        return unless subject.hasSemanticProperty?(statement.predicate.value)

        prop_name = statement.predicate.fragment
        setter_name = "#{prop_name}="

        return unless subject.respond_to?(setter_name)

        value = statement.object.object
        subject.public_send(setter_name, value)
      end
    end
  end
end
