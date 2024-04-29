# frozen_string_literal: true

class EnterpriseBuilder < DfcBuilder
  def self.enterprise(enterprise) # rubocop:disable Metrics/AbcSize
    # The ABC size of this method should shrink when our custom attributes are
    # in the DFC standard.

    variants = enterprise.supplied_variants.to_a
    catalog_items = variants.map(&method(:catalog_item))
    supplied_products = catalog_items.map(&:product)
    address = AddressBuilder.address(enterprise.address)

    DataFoodConsortium::Connector::Enterprise.new(
      urls.enterprise_url(enterprise.id),
      name: enterprise.name,
      description: enterprise.description,
      vatNumber: enterprise.abn,
      suppliedProducts: supplied_products,
      catalogItems: catalog_items,
      emails: [enterprise.email_address].compact,
      localizations: [address],
      phoneNumbers: [enterprise.phone].compact,
      socialMedias: SocialMediaBuilder.social_medias(enterprise),

      # The model strips the protocol and we need to add it:
      websites: [enterprise.website].compact_blank.map { |url| "https://#{url}" },
    ).tap do |e|
      add_ofn_property(e, "ofn:long_description", enterprise.long_description)

      # This could be expressed as dfc-b:hasMainContact Person with name.
      # But that would require a new endpoint for a single string.
      add_ofn_property(e, "ofn:contact_name", enterprise.contact_name)

      add_ofn_property(e, "ofn:logo_url", enterprise.logo_url(:small))
      add_ofn_property(e, "ofn:promo_image_url", enterprise.promo_image_url(:large))
    end
  end

  def self.add_ofn_property(dfc_enterprise, property_name, value)
    dfc_enterprise.registerSemanticProperty(property_name) { value }
  end

  def self.enterprise_group(group)
    members = group.enterprises.map do |member|
      urls.enterprise_url(member.id)
    end

    DataFoodConsortium::Connector::Enterprise.new(
      urls.enterprise_group_url(group.id),
      name: group.name,
      description: group.description,
    ).tap do |enterprise|
      # This property has been agreed by the DFC but hasn't made it's way into
      # the Connector yet.
      enterprise.registerSemanticProperty("dfc-b:affiliatedBy") do
        members
      end
    end
  end
end
