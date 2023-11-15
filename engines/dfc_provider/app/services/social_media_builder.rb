# frozen_string_literal: true

class SocialMediaBuilder < DfcBuilder
  NAMES = %w(facebook instagram linkedin twitter whatsapp_phone).freeze

  def self.social_medias(enterprise)
    NAMES.map do |name|
      social_media(enterprise, name)
    end.compact
  end

  def self.social_media(enterprise, name)
    return nil unless name.in?(NAMES)

    url =  enterprise.attributes[name]

    return nil if url.blank?

    DataFoodConsortium::Connector::SocialMedia.new(
      urls.enterprise_social_media_url(enterprise.id, name),
      name:, url:,
    )
  end
end
