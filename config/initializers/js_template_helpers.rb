# Make helpers (#t in particular) available to javascript templates
# https://github.com/pitr/angular-rails-templates/issues/45#issuecomment-43229086

Rails.application.assets.context_class.class_eval do
  # include ApplicationHelper
  # include ActionView::Helpers
  # include Rails.application.routes.url_helpers

  # Including all of the helpers (above) has caused some intermittent CSS include issues
  # (not finding mixins from an @include in sass). Therefore, we're only including the
  # bare minimum here.
  include ActionView::Helpers::TranslationHelper
end
