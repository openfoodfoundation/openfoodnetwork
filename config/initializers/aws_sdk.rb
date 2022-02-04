# frozen_string_literal: false

if AWS::VERSION == "1.67.0"
  module AWS
    module Core
      module Signers
        # @api private
        class S3
          module URI
            def self.escape(string)
              ::URI::RFC2396_Parser.new.escape(string)
            end
          end
        end
      end
    end
  end
else
  Rails.logger.warn "The aws-sdk patch needs updating or removing."
end
