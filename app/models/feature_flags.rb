# Tells whether a particular feature is enabled or not
class FeatureFlags
  # Constructor
  #
  # @param user [User]
  def initialize(user)
    @user = user
  end

  # Checks whether product import is enabled for the specified user
  #
  # @return [Boolean]
  def product_import_enabled?
    superadmin?
  end

  # Checks whether the "Enterprise Fee Summary" is enabled for the specified user
  #
  # @return [Boolean]
  def enterprise_fee_summary_enabled?
    superadmin?
  end

  private

  attr_reader :user

  # Checks whether the specified user is a superadmin, with full control of the
  # instance
  #
  # @return [Boolean]
  def superadmin?
    user.has_spree_role?('admin')
  end
end
