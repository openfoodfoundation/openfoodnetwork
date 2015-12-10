module OpenFoodNetwork
  class EnterpriseIssueValidator
    include Rails.application.routes.url_helpers
    include Spree::Core::UrlHelpers

    def initialize(enterprise)
      @enterprise = enterprise
    end

    def issues
      issues = []

      issues << {
        description: "#{@enterprise.name} currently has no shipping methods.",
        link: "<a class='button fullwidth' href='#{spree.new_admin_shipping_method_path}'>Create New</a>"
      } unless shipping_methods_ok?

      issues << {
        description: "#{@enterprise.name} currently has no payment methods.",
        link: "<a class='button fullwidth' href='#{spree.new_admin_payment_method_path}'>Create New</a>"
      } unless payment_methods_ok?

      issues << {
        description: "Email confirmation is pending. We've sent a confirmation email to #{@enterprise.email}.",
        link: "<a class='button fullwidth' href='#{enterprise_confirmation_path(enterprise: { id: @enterprise.id, email: @enterprise.email } )}' method='post'>Resend Email</a>"
      } unless confirmed?

      issues
    end

    def issues_summary(opts={})
      if    !opts[:confirmation_only] && !shipping_methods_ok? && !payment_methods_ok?
        'no shipping or payment methods'
      elsif !opts[:confirmation_only] && !shipping_methods_ok?
        'no shipping methods'
      elsif !opts[:confirmation_only] && !payment_methods_ok?
        'no payment methods'
      elsif !confirmed?
        'unconfirmed'
      end
    end

    def warnings
      warnings = []

      warnings << {
        description: "#{@enterprise.name} is not visible and so cannot be found on the map or in searches",
        link: "<a class='button fullwidth' href='#{edit_admin_enterprise_path(@enterprise)}'>Edit</a>"
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
