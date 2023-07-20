# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require "web/version"

Gem::Specification.new do |s|
  s.name        = "web"
  s.version     = Web::VERSION
  s.authors     = ["developers@ofn"]
  s.summary     = "Web domain of the OFN solution."

  s.required_ruby_version = File.read(File.expand_path("../../.ruby-version", __dir__)).chomp

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.rdoc"]
  s.metadata['rubygems_mfa_required'] = 'true'
end
