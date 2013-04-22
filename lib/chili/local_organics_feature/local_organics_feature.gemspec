$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "local_organics_feature/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "local_organics_feature"
  s.version     = LocalOrganicsFeature::VERSION
  s.authors     = ["Rohan Mitchell"]
  s.email       = ["rohan@rohanmitchell.com"]
  s.homepage    = ""
  s.summary     = "Summary of LocalOrganicsFeature."
  s.description = "Description of LocalOrganicsFeature."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["README.rdoc"]

  s.add_dependency "rails", "~> 3.2.11"
  s.add_dependency 'chili', '~> 3.1'

  s.add_development_dependency "sqlite3"
end
