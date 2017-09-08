module Spree
  module ConfigHelper
    def with_spree_config(hash)
      stored = config_slice(hash.keys)
      Config.set(hash)
      yield
      Config.set(stored)
    end

    private

    def config_slice(keys)
      keys.each_with_object({}) do |key, hash|
        hash[key] = Config[key]
      end
    end
  end
end
