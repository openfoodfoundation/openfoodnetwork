# frozen_string_literal: true

# This patch fixes the Rails issue where ActionDispatch::Request#deep_munge was converting empty
# array paramters into nils, see https://github.com/rails/rails/issues/13420
#
# Before this patch:
#
# | JSON                             | Hash                    |
# |----------------------------------|-------------------------|
# | { "person": [] }                 | { 'person' => nil }     |
#
# After patch:
#
# | JSON                             | Hash                    |
# |----------------------------------|-------------------------|
# | { "person": [] }                 | { 'person' => [] }      |
#
# The issue started in Rails v4.0.0.beta1:
#
# https://github.com/rails/rails/commit/8e577fe560d5756fcc67840ba304d79ada6804e4
#
# This patch can be removed on or after Rails v5.0.0.beta1 when the issue was fixed:
#
# https://github.com/rails/rails/commit/8f8ccb9901cab457c6e1d52bdb25acf658fd5777
#
# Credit:
#
# https://gist.github.com/victorblasco/f675b4cbaf9c0bc19f81

module ActionDispatch
  class Request < Rack::Request
    class Utils # :nodoc:
      mattr_accessor :perform_deep_munge
      self.perform_deep_munge = true

      class << self
        # Remove nils from the params hash
        def deep_munge(hash, keys = [])
          return hash unless perform_deep_munge

          hash.each do |key, value|
            deep_munge_value(key, value, keys)
          end

          hash
        end

        def deep_munge_value(key, value, keys)
          keys << key
          case value
          when Array
            value.grep(Hash) { |x| deep_munge(x, keys) }
            value.compact!

            # This patch removes the following lines
            # if v.empty?
            #   hash[k] = nil
            # ActiveSupport::Notifications.instrument("deep_munge.action_controller",
            #                                         keys: keys)
            # end
          when Hash
            deep_munge(value, keys)
          end
          keys.pop
        end
      end
    end
  end
end
