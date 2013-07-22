require 'open_food_web/feature_toggle'

module EnterprisesDistributorInfoRichTextFeature
  class Engine < ::Rails::Engine
    isolate_namespace EnterprisesDistributorInfoRichTextFeature

    initializer 'enterprises_distributor_info_rich_text_feature.mailer', :after => :load_config_initializers do |app|
      if OpenFoodWeb::FeatureToggle.enabled? :enterprises_distributor_info_rich_text
        ::Spree::OrderMailer.class_eval do
          helper FeatureHelper

          def confirm_email(order, resend = false)
            @order = order
            subject = (resend ? "[#{t(:resend).upcase}] " : '')
            subject += "#{Spree::Config[:site_name]} #{t('order_mailer.confirm_email.subject')} ##{order.number}"

            mail(:to => order.email,
                 :subject => subject,
                 :template_name => 'confirm_email_with_distributor_info')
          end
        end
      end
    end
  end
end
