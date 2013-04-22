$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "eaterprises_feature/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "eaterprises_feature"
  s.version     = EaterprisesFeature::VERSION
  s.authors     = ["Rohan Mitchell"]
  s.email       = ["rohan@rohanmitchell.com"]
  s.homepage    = ""
  s.summary     = "Summary of EaterprisesFeature."
  s.description = "Description of EaterprisesFeature."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.11"
  s.add_dependency 'chili', '~> 3.1'

  s.add_development_dependency "sqlite3"
end
