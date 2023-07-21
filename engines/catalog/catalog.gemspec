# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require "catalog/version"

Gem::Specification.new do |s|
  s.name        = "catalog"
  s.version     = Catalog::VERSION
  s.authors     = ["developers@ofn"]
  s.summary     = "Catalog domain of the OFN solution."

  s.required_ruby_version = File.read(File.expand_path("../../.ruby-version", __dir__)).chomp

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.rdoc"]
  s.metadata['rubygems_mfa_required'] = 'true'
end
