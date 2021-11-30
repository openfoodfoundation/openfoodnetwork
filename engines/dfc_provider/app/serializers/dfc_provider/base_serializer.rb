# frozen_string_literal: true

# Serializer used to render the DFC Address from an OFN User
# into JSON-LD format based on DFC ontology
module DfcProvider
  class BaseSerializer < ActiveModel::Serializer
    include DfcProvider::Engine.routes.url_helpers

    class << self
      def default_url_options
        Rails.application.config.action_mailer.default_url_options
      end
    end

    def base_url
      [
        self.class.default_url_options[:protocol] || 'https',
        self.class.default_url_options[:host]
      ].join('://')
    end
  end
end
