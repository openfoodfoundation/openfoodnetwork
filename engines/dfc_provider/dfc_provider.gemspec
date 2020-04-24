# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require "dfc_provider/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'dfc_provider'
  s.version     = DfcProvider::VERSION
  s.authors     = ['Admin OFF']
  s.email       = ['admin@openfoodfrance.org']
  s.summary     = 'Provides an API stack implementing DFC semantic specifications'

  s.files = Dir["{app,config,db,lib}/**/*"] + ['README.rdoc']
  s.test_files = Dir['test/**/*']
end
