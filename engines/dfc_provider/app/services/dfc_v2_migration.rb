# frozen_string_literal: true

# Transform DFC v1 data to DFC v2.
class DfcV2Migration
  def initialize
    @cache = {}
  end

  def up(*objects)
    objects.map(&method(:up_one))
  end

  def up_one(object)
    return @cache[object] if @cache.key?(object)

    case object
    when Array
      object.map { |item| up_one(item) }
    when DataFoodConsortium::ConnectorV1::Enterprise
      up_enterprise(object)
    when DataFoodConsortium::ConnectorV1::Person
      up_person(object)
    when VirtualAssembly::Semantizer::SemanticObject
      up_generic(object)
    else
      # Not sure what this is but we can't migrate it and leave it as is.
      memoize(object, object)
    end
  end

  def up_enterprise(enterprise)
    # We introduce new ids for our enterprises on the new version of the API.
    # This is not strictly necessary but will make the API more consistent
    # in the future. Since DFC v2 is a big breaking change, we may use that
    # to ignore any requirement to be backwards compatible here.
    #
    # If an old integration upgrades to DFC v2, they have to update their
    # internally stored ids for enterprises.
    id = enterprise.semanticId.sub("/api/dfc/enterprises/", "/api/dfc/organizations/")

    DataFoodConsortium::Connector::Organization.new(id).tap do |org|
      memoize(enterprise, org)
      copy_property_values(enterprise, org)
    end
  end

  def up_person(person)
    id = person.semanticId.sub("/api/dfc/enterprises/", "/api/dfc/organizations/")
    up_generic(person, id)
  end

  def up_generic(object, id = object.semanticId, **)
    v1_class = object.class.ancestors.find do |ancestor|
      ancestor.module_parent == DataFoodConsortium::ConnectorV1
    end

    # It may be DfcV2 already, or something unknown.
    return memoize(object, object) if v1_class.nil?

    class_name = v1_class.name.demodulize
    unless DataFoodConsortium::Connector.const_defined?(class_name, false)
      return memoize(object, object)
    end

    v2_class = DataFoodConsortium::Connector.const_get(class_name, false)

    # Some classes like QuantitativeValue don't have a semantic id.
    constructor = v2_class.instance_method(:initialize)
    instance = if constructor.parameters.include?([:req, :semanticId])
                 v2_class.new(id, **)
               else
                 v2_class.new(**)
               end

    memoize(object, instance)
    copy_property_values(object, instance)

    instance
  end

  def copy_property_values(from, to)
    to.semanticProperties.each do |property|
      next if property.value.present?

      value = from.semanticPropertyValue(property.name)

      next if value.blank?

      property.value = up_one(value)
    end
  end

  private

  # Remember the result of a migration before copying property values.
  #
  # Property values can point back to the object we are migrating right now.
  # We need to know about that object before we follow its references,
  # otherwise the recursion would never end.
  def memoize(from, to)
    @cache[from] = to
  end
end
