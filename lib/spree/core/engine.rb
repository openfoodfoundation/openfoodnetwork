# frozen_string_literal: true

module Spree
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Spree
      engine_name 'spree'

      config.autoload_paths += %W(#{config.root}/lib)
    end
  end
end
