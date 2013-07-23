$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "enterprises_distributor_info_rich_text_feature/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "enterprises_distributor_info_rich_text_feature"
  s.version     = EnterprisesDistributorInfoRichTextFeature::VERSION
  s.authors     = ["Rohan Mitchell"]
  s.email       = ["rohan@rohanmitchell.com"]
  s.homepage    = ""
  s.summary     = "Summary of EnterprisesDistributorInfoRichTextFeature."
  s.description = "Description of EnterprisesDistributorInfoRichTextFeature."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["README.rdoc"]

  s.add_dependency "rails", "~> 3.2.11"
  s.add_dependency 'chili', '~> 3.1'

  s.add_development_dependency "sqlite3"
end
