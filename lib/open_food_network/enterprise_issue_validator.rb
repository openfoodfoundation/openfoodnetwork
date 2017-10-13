module OpenFoodNetwork
  class EnterpriseIssueValidator
    include Rails.application.routes.url_helpers
    include Spree::TestingSupport::UrlHelpers

    def initialize(enterprise)
      @enterprise = enterprise
    end

    def issues
      issues = []

      issues << {
        description: I18n.t('admin.enterprise_issues.has_no_shipping_methods', enterprise: @enterprise.name),
        link: "<a class='button fullwidth' href='#{spree.new_admin_shipping_method_path}'>#{I18n.t('admin.enterprise_issues.create_new')}</a>"
      } unless shipping_methods_ok?

      issues << {
        description: I18n.t('admin.enterprise_issues.has_no_payment_methods', enterprise: @enterprise.name),
        link: "<a class='button fullwidth' href='#{spree.new_admin_payment_method_path}'>#{I18n.t('admin.enterprise_issues.create_new')}</a>"
      } unless payment_methods_ok?

      issues << {
        description: I18n.t('admin.enterprise_issues.email_confirmation', email: @enterprise.email),
        link: "<a class='button fullwidth' href='#{enterprise_confirmation_path(enterprise: { id: @enterprise.id, email: @enterprise.email } )}' method='post'>#{I18n.t('admin.enterprise_issues.resend_email')}</a>"
      } unless confirmed?

      issues
    end

    def issues_summary(opts={})
      if    !opts[:confirmation_only] && !shipping_methods_ok? && !payment_methods_ok?
        I18n.t(:no_shipping_or_payment)
      elsif !opts[:confirmation_only] && !shipping_methods_ok?
        I18n.t(:no_shipping)
      elsif !opts[:confirmation_only] && !payment_methods_ok?
        I18n.t(:no_payment)
      elsif !confirmed?
        I18n.t(:unconfirmed)
      end
    end

    def warnings
      warnings = []

      warnings << {
        description: I18n.t('admin.enterprise_issues.not_visible', enterprise: @enterprise.name),
        link: "<a class='button fullwidth' href='#{edit_admin_enterprise_path(@enterprise)}'>#{I18n.t(:edit)}</a>"
      } unless @enterprise.visible

      warnings
    end


    private

    def shipping_methods_ok?
      # Refactor into boolean
      return true unless @enterprise.is_distributor
      @enterprise.shipping_methods.any?
    end

    def payment_methods_ok?
      return true unless @enterprise.is_distributor
      @enterprise.payment_methods.available.any?
    end

    def confirmed?
      @enterprise.confirmed?
    end
  end
end
