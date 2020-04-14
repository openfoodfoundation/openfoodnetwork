$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dfc_provider/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'dfc_provider'
  s.version     = DfcProvider::VERSION
  s.authors     = ['Admin OFF']
  s.email       = ['admin@openfoodfrance.org']
  s.summary     = 'Provdes an API stack implementing DFC semantic specifications'

  s.files = Dir["{app,config,db,lib}/**/*"] + ['MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']
end
