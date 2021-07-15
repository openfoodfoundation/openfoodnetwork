# frozen_string_literal: true

class ImageImporter
  # Accessing any URI provided by the user has the risk of server side request
  # forgery (SSRF). We need to make sure that we only access public servers
  # and that we deny access to the local network. A user controlled domain can
  # resolve to a local IP address or the destination can redirect to a local IP
  # address. We are whitelisting well known CDN domains here which are not
  # controlled by the user and don't redirect to user-defined addresses.
  # https://medium.com/in-the-weeds/8cb2b1c96fe8
  module URIValidator
    class Error < StandardError
      def initialize(msg)
        super(I18n.t(msg, scope: "image_importer.uri_validator.error"))
      end
    end

    ALLOWED_DOMAINS = [
      "cdn.digitaloceanspaces.com",
    ].freeze

    def self.validate!(url)
      uri = URI.parse(url)

      raise Error, :connection_not_protected unless uri.scheme == "https"
      raise Error, :domain_not_allowed unless domain_allowed?(uri.host)

      uri
    end

    def self.domain_allowed?(domain)
      ALLOWED_DOMAINS.any? do |good_domain|
        domain == good_domain ||
          domain.ends_with?(".#{good_domain}")
      end
    end
  end

  def import(url, product)
    uri = URIValidator.validate!(url)
    product.master.images.new(
      attachment: uri.open,
    )
  end
end
