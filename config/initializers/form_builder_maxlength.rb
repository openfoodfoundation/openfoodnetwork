# frozen_string_literal: true

# Governance for the automatic `maxlength` attribute injection in
# config/initializers/form_builder.rb.
#
# Automatic maxlength is disabled in the test environment so that system
# specs exercise the real server-side length validation (the model validators
# and the database length limits) rather than the client-side clamp. Field
# specs that target the injection itself can re-enable it via
# `FormBuilderMaxlength.enabled = true`.
module FormBuilderMaxlength
  class << self
    attr_writer :enabled

    def enabled?
      return @enabled unless @enabled.nil?

      !Rails.env.test?
    end
  end
end
