# frozen_string_literal: true

# Upgrade HAML attribute syntax to prepare for HAML 6.
#
# HAML 6 stopped supporting nested hash attributes other than `data` and `aria`.
# We used to be able to write:
#
#     %div{ ng: { class: "upper", bind: "model" } }
#
# This needs to be written in a flat structure now:
#
#     %div{ "ng-class" => "upper", "ng-bind" => "model" }
#
require "fileutils"
require "haml"

class HamlUp
  def upgrade_file(filename)
    template = File.read(filename)
    rewrite_template(template)
    File.write(filename, template)
  end

  def rewrite_template(template)
    haml_attributes(template).compact.each do |attributes|
      rewrite_attributes(template, attributes)
    end
  end

  def rewrite_attributes(template, original)
    attributes = parse_attributes(original)

    if attributes.nil? # parser failed
      puts "Warning: failed to parse:\n" # rubocop:disable Rails/Output
      puts original # rubocop:disable Rails/Output
      return
    end

    parse_deprecated_hashes(attributes)

    to_transform = attributes.select { |_k, v| v.is_a? Hash }

    return if to_transform.empty?

    to_transform.each do |key, hash|
      add_full_keys(attributes, key, hash)
      attributes.delete(key)
    end

    replace_attributes(template, original, attributes)
  end

  def haml_attributes(template)
    options = Haml::Options.new
    parsed_tree = Haml::Parser.new(options).call(template)
    elements = flatten_tree(parsed_tree)
    elements.map { |e| e.value[:dynamic_attributes]&.old }
  end

  def flatten_tree(parent)
    parent.children.flat_map do |child|
      [child, *flatten_tree(child)]
    end
  end

  def parse_attributes(string)
    Haml::AttributeParser.parse(string)
  end

  def parse_deprecated_hashes(hash)
    hash.each do |key, value|
      next if ["aria", "data"].include?(key)

      parsed = parse_attributes(value)
      next unless parsed.is_a? Hash

      parse_deprecated_hashes(parsed)
      hash[key] = parsed
    end
  end

  def add_full_keys(attributes, key, hash)
    hash.each do |subkey, value|
      full_key = "#{key}-#{subkey}"
      if value.is_a? Hash
        add_full_keys(attributes, full_key, value)
      else
        attributes[full_key] = value
      end
    end
  end

  def replace_attributes(template, original, attributes)
    parsed_lines = original.split("\n")
    lines_as_regex = parsed_lines.map(&Regexp.method(:escape))
    pattern = lines_as_regex.join("\n\s*")

    template.gsub!(/#{pattern}/, stringify(attributes))
  end

  def stringify(hash)
    entries = hash.map do |key, value|
      value = stringify(value) if value.is_a? Hash

      # We prefer the Ruby 1.9 hash syntax with symbols followed by a colon
      # like this:
      #
      #   %button{ disabled: true, "ng-class": "primary-button" }
      #
      # Symbols start with `:` which we slice off. It gets appended below.
      key = key.to_sym.inspect.slice(1..-1)

      "#{key}: #{value}"
    end

    "{ #{entries.join(', ')} }"
  end
end
