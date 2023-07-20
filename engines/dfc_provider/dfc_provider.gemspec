# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require "dfc_provider/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'dfc_provider'
  spec.version     = DfcProvider::VERSION
  spec.authors     = ["developers@ofn"]
  spec.summary     = 'Provides an API stack implementing DFC semantic ' \
                     'specifications'

  spec.required_ruby_version = File.read(File.expand_path("../../.ruby-version", __dir__)).chomp

  spec.files = Dir["{app,config,lib}/**/*"] + ['README.md']

  spec.metadata['rubygems_mfa_required'] = 'true'
end
