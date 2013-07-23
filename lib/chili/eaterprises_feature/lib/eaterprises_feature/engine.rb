require_relative '../../../../open_food_web/feature_toggle'

module EaterprisesFeature
  class Engine < ::Rails::Engine
    isolate_namespace EaterprisesFeature

    if OpenFoodWeb::FeatureToggle.enabled? :eaterprises
      initializer 'eaterprises_feature.sass', :after => :load_config_initializers do |app|
        app.config.sass.load_paths += [self.root.join('app', 'assets', 'stylesheets', 'eaterprises_feature')] if Rails.application.config.respond_to? :sass
      end

      initializer :assets do |app|
        app.config.assets.precompile += ['eaterprises_feature/*']
      end
    end
  end
end
