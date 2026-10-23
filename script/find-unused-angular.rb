#!/usr/bin/env ruby
# frozen_string_literal: true

# Lists AngularJS components (services, directives, controllers, filters etc.)
# under app/assets/javascripts that nothing outside of specs refers to.
#
#   script/find-unused-angular.rb
#
# A reference only counts if it comes from a file that is still in use, so a
# service injected only by an unused controller is reported as well.
#
# The search is textual. Names built at runtime are not found, so check each
# result by hand before deleting it.
#
# When deleting a file that declares a module, like `angular.module('x', [])`,
# remove that module from the dependency lists of other modules too.

Dir.chdir(File.expand_path("..", __dir__))

REGISTRATION = /
  \.(factory|service|directive|controller|filter|provider|value|constant)
  \s*\(?\s*['"]([\w$]+)['"]
/x

def kebab(name)
  name.gsub(/([A-Z])/) { "-#{::Regexp.last_match(1).downcase}" }
end

def patterns(kind, name)
  case kind
  when "directive"
    # angular-foundation's $tooltip loads `fooPopup` for the `foo` directive.
    dashed = kebab(name.delete_suffix("Popup"))
    [
      /(?<![\w-])(data-)?#{Regexp.escape(dashed)}(?![\w-])/,
      /(?<![\w-])#{Regexp.escape(dashed.tr('-', '_'))}(?![\w-])/,
    ]
  when "filter"
    [
      /\|\s*#{Regexp.escape(name)}\b/,
      /\b#{Regexp.escape(name)}Filter\b/,
      /\$filter\(\s*['"]#{Regexp.escape(name)}['"]/,
    ]
  else
    [/(?<![\w$.])#{Regexp.escape(name)}(?![\w$])/]
  end
end

angular_files = Dir["app/assets/javascripts/**/*.{coffee,js,erb}"]
  .reject { |path| path.end_with?(".min.js") }

definitions = angular_files.flat_map do |path|
  File.read(path, encoding: "UTF-8").scan(REGISTRATION).map do |kind, name|
    # Services are only injected from JS or templates. Ruby classes like
    # `Checkout` would hide them otherwise.
    ruby = !%w[factory service provider value constant].include?(kind)
    { kind:, name:, path:, ruby:, patterns: patterns(kind, name) }
  end
end

sources = `git ls-files app engines lib config`.split
  .grep(/\.(coffee|js|erb|haml|html|rb|slim)\z/)
  .reject { |path| path.end_with?(".min.js") }
  .select { |path| File.file?(path) }
  .to_h { |path| [path, File.read(path, encoding: "UTF-8").scrub] }

unused = []
loop do
  # A file only defining unused components doesn't keep anything alive.
  dead_files = definitions.group_by { |d| d[:path] }
    .select { |_, defs| defs.all? { |d| unused.include?(d) } }
    .keys

  newly_unused = (definitions - unused).reject do |definition|
    sources.any? do |path, text|
      # Mentions inside the defining file, like `new class Checkout`, don't count.
      next false if path == definition[:path] || dead_files.include?(path)
      next false if !definition[:ruby] && path.end_with?(".rb")

      definition[:patterns].any? { |pattern| text.match?(pattern) }
    end
  end
  break if newly_unused.empty?

  unused.concat(newly_unused)
end

unused.sort_by { |d| [d[:path], d[:name]] }.each do |definition|
  puts "#{definition[:path]}: #{definition[:kind]} #{definition[:name]}"
end
