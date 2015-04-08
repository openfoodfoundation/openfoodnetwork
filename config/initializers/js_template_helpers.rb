# Make helpers (#t in particular) available to javascript templates
# https://github.com/pitr/angular-rails-templates/issues/45#issuecomment-43229086

Rails.application.assets.context_class.class_eval do
  include ApplicationHelper
  include ActionView::Helpers
  include Rails.application.routes.url_helpers
end
