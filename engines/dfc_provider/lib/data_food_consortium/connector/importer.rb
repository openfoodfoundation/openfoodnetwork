# frozen_string_literal: true

require_relative "skos_parser"

module DataFoodConsortium
  module Connector
    class Importer # rubocop:disable Metrics/ClassLength
      TYPES = [
        DataFoodConsortium::Connector::CatalogItem,
        DataFoodConsortium::Connector::Enterprise,
        DataFoodConsortium::Connector::Offer,
        DataFoodConsortium::Connector::Person,
        DataFoodConsortium::Connector::QuantitativeValue,
        DataFoodConsortium::Connector::SuppliedProduct,
      ].freeze

      def self.type_map
        unless @type_map
          @type_map = {}
          TYPES.each(&method(:register_type))
        end

        @type_map
      end

      def self.register_type(clazz)
        # Methods with variable arguments have a negative arity of -n-1
        # where n is the number of required arguments.
        number_of_required_args = -1 * (clazz.instance_method(:initialize).arity + 1)
        args = Array.new(number_of_required_args)
        type_uri = clazz.new(*args).semanticType
        type_map[type_uri] = clazz
      end

      def self.prefixed_name(uri)
        # When we skip backwards compatibility, we can just do this:
        #
        #     key = RDF::URI.new(uri).pname(prefixes: Context::VERSION_1_8)
        #
        # But for now we do it manually.
        uri.gsub(
          "https://github.com/datafoodconsortium/ontology/releases/latest/download/DFC_BusinessOntology.owl#",
          "dfc-b:"
        ).gsub(
          # legacy URI
          "http://static.datafoodconsortium.org/ontologies/DFC_BusinessOntology.owl#",
          "dfc-b:"
        )
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
        key = self.class.prefixed_name(type)
        clazz = self.class.type_map[key]

        clazz.new(*[id].compact)
      end

      def apply_statements(statements)
        statements.each do |statement|
          apply_statement(statement)
        end
      end

      def apply_statement(statement)
        subject = subject_of(statement)
        property_uri = statement.predicate.value
        value = resolve_object(statement.object)

        property_id = self.class.prefixed_name(property_uri)

        return unless subject.hasSemanticProperty?(property_id)

        property = subject.semanticProperty(property_id)

        if property.value.is_a?(Enumerable)
          property.value << value
        else
          setter = guess_setter_name(statement)
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
        id = object.value.sub(
          "http://static.datafoodconsortium.org/data/measures.rdf#", "dfc-m:"
        ).sub(
          "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/measures.rdf#",
          "dfc-m:"
        ).sub(
          "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#",
          "dfc-pt:"
        )

        SKOSParser.concepts[id]
      end

      def guess_setter_name(statement)
        predicate = statement.predicate

        # Ideally the product models would be consitent with the rule below and use "type"
        # instead of "productType" but alast they are not so we need this exception
        return "productType=" if predicate.fragment == "hasType" && product_type?(statement)

        name =
          # Some predicates are named like `hasQuantity`
          # but the attribute name would be `quantity`.
          predicate.fragment&.sub(/^has/, "")&.camelize(:lower) ||
          # And sometimes the URI looks like `ofn:spree_product_id`.
          predicate.to_s.split(":").last

        "#{name}="
      end

      def product_type?(statement)
        return true if statement.object.literal? && statement.object.value.match("dfc-pt")

        return true if statement.object.path.match("productTypes")

        false
      end
    end
  end
end
