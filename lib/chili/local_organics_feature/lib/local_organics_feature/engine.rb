require_relative '../../../../open_food_web/feature_toggle'

module LocalOrganicsFeature
  class Engine < ::Rails::Engine
    isolate_namespace LocalOrganicsFeature

    if OpenFoodWeb::FeatureToggle.enabled? :local_organics
      initializer 'local_organics_feature.sass', :after => :load_config_initializers do |app|
        app.config.sass.load_paths += [self.root.join('app', 'assets', 'stylesheets', 'local_organics_feature')] if Rails.application.config.respond_to? :sass
      end

      initializer :assets do |app|
        app.config.assets.precompile += ['local_organics_feature/*']
      end
    end
  end
end
