module LocalOrganicsFeature
  class Engine < ::Rails::Engine
    isolate_namespace LocalOrganicsFeature

    if ENV['OFW_DEPLOYMENT'] == 'local_organics'
      initializer 'local_organics_feature.sass', :after => :load_config_initializers do |app|
        app.config.sass.load_paths += [self.root.join('app', 'assets', 'stylesheets', 'local_organics_feature')]
      end
    end
  end
end
