module EaterprisesFeature
  class Engine < ::Rails::Engine
    isolate_namespace EaterprisesFeature

    if ENV['OFW_DEPLOYMENT'] == 'eaterprises'
      initializer 'eaterprises_feature.sass', :after => :load_config_initializers do |app|
        app.config.sass.load_paths += [self.root.join('app', 'assets', 'stylesheets', 'eaterprises_feature')]
      end

      initializer :assets do |app|
        app.config.assets.precompile += ['eaterprises_feature/*']
      end
    end
  end
end
