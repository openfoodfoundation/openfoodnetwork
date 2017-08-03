# `spree_auth_devise` gem decorators get loaded in a `to_prepare` callback
# referring to Spree classes that have not been loaded yet
#
# When this initializer is loaded we're sure that those Spree classes have been
# loaded and we load again the `spree_auth_devise` decorators to effectively
# apply them.
#
# Give a look at `if defined?(Spree::Admin::BaseController)` in the following file
# to get an example:
# https://github.com/openfoodfoundation/spree_auth_devise/blob/spree-upgrade-intermediate/app/controllers/spree/admin/admin_controller_decorator.rb#L1
#
# TODO: remove this hack once we get to Spree 3.0
gem_dir = Gem::Specification.find_by_name("spree_auth_devise").gem_dir
Dir.glob(File.join(gem_dir, 'app/**/*_decorator*.rb')) do |c|
  load c
end
