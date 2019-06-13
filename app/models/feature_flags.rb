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
    user.superadmin?
  end

  private

  attr_reader :user
end
