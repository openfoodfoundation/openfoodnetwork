# Make helpers (#t in particular) available to javascript templates
# https://github.com/pitr/angular-rails-templates/issues/45#issuecomment-43229086

# if ENV['DEPENDENCIES_NEXT']
  Rails.application.config.assets.configure do |env|
    env.context_class.class_eval do
      include ActionView::Helpers::TranslationHelper
    end
  end
# else
#   Rails.application.assets.context_class.class_eval do
#     include ActionView::Helpers::TranslationHelper
#   end
# end
