# frozen_string_literal: true

require "private_address_check"
require "private_address_check/tcpsocket_ext"

class EnterpriseImporter
  def initialize(owner, dfc_enterprise)
    @owner = owner
    @dfc_enterprise = dfc_enterprise
  end

  def import
    enterprise = find || new

    apply(enterprise)

    enterprise
  end

  def find
    semantic_id = @dfc_enterprise.semanticId

    @owner.owned_enterprises.includes(:semantic_link)
      .find_by(semantic_link: { semantic_id: })
  end

  def new
    @owner.owned_enterprises.new(
      address: Spree::Address.new,
      semantic_link: SemanticLink.new(semantic_id: @dfc_enterprise.semanticId),
      is_primary_producer: true,
      visible: "public",
    )
  end

  def apply(enterprise)
    address = @dfc_enterprise.localizations.first
    country = find_country(address)

    enterprise.name = @dfc_enterprise.name
    enterprise.address.assign_attributes(
      address1: address.street,
      city: address.city,
      zipcode: address.postalCode,
      state: find_state(country, address),
      country:,
    )
    enterprise.email_address = @dfc_enterprise.emails.first
    enterprise.description = @dfc_enterprise.description
    enterprise.phone = @dfc_enterprise.phoneNumbers.first&.phoneNumber
    enterprise.website = @dfc_enterprise.websites.first
    apply_social_media(enterprise)
    apply_logo(enterprise)
  end

  def apply_social_media(enterprise)
    attributes = {}
    @dfc_enterprise.socialMedias.each do |media|
      attributes[media.name.downcase] = media.url
    end
    attributes["twitter"] = attributes.delete("x") if attributes.key?("x")
    enterprise_attributes = attributes.slice(*SocialMediaBuilder::NAMES)
    enterprise.assign_attributes(enterprise_attributes)
  end

  def apply_logo(enterprise)
    link = @dfc_enterprise.logo
    logo = enterprise.logo

    return if link.blank?
    return if logo.blob && (logo.blob.custom_metadata&.fetch("origin", nil) == link)

    url = URI.parse(link)
    filename = File.basename(url.path)
    metadata = { custom: { origin: link } }

    PrivateAddressCheck.only_public_connections do
      logo.attach(io: url.open, filename:, metadata:)
    end
  rescue StandardError
    # Any URL parsing or network error shouldn't impact the import
    # at all. Maybe we'll add UX for error handling later.
    nil
  end

  def find_country(address)
    country = address.country
    country = country[:path] if country.is_a?(Hash)

    Spree::Country.find_by(iso3: country.to_s[-3..]) ||
      Spree::Country.find_by(name: country) ||
      Spree::Country.first
  end

  def find_state(country, address)
    country.states.find_by(name: address.region) || country.states.first
  end
end
