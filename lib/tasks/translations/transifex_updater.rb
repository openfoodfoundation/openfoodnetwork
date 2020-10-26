# frozen_string_literal: true

require 'yaml'

class TransifexUpdater
  def update
    return unless updatable_locales.present? && tx_client_present?

    fetch_translations
    update_translations
  end

  private

  def updatable_locales
    locales = ENV.fetch("AVAILABLE_LOCALES", "").split(",").collect(&:strip)
    locales.delete("en")
    locales
  end

  def tx_client_present?
    log "Transifex Client:"
    system("tx --version")
  end

  # Fetches translations for available locales that have changed since the local git version.
  # Any updated translations are saved in a separate file (eg `fr.yml.new`) and the original
  # file (eg `fr.yml`) is left untouched.
  def fetch_translations
    system("tx pull --use-git-timestamps --disable-overwrite -l #{updatable_locales.join(',')}")
  end

  # Processes each new translation file (if any) and applies updates to original
  def update_translations
    return unless new_translation_files.any?

    new_translation_files.each do |new_file|
      current_file = new_file.chomp('.new')
      updated_translations = apply_updates(current_file, new_file)

      File.open(current_file, "w") do |file|
        file.write updated_translations.to_yaml(line_width: -1)
      end

      File.delete(new_file)
    end
  end

  def apply_updates(current_file, new_file)
    current_translations = YAML.load_file(current_file)
    upstream_translations = YAML.load_file(new_file)

    locale_key = root_key(current_translations)

    log "\n####### Processing locale: #{locale_key} #######\n"

    log "####### New compatible keys in basefile for #{locale_key}:\n"
    updated_structure = { locale_key =>
                              merge_keys(keys(current_translations), keys(base_translations)) }

    log "\n####### New/updated compatible translations for #{locale_key}:\n"
    merge_values(updated_structure, upstream_translations)
  end

  # The root key in any locale, eg: "fr"
  def root_key(translations)
    translations.first[0]
  end

  # Everything else underneath the root_key
  def keys(translations)
    translations.first[1]
  end

  def new_translation_files
    Dir.glob(Rails.root.join("config/locales/*.new"))
  end

  def base_translations
    YAML.load_file(Rails.root.join("config/locales/en.yml"))
  end

  # Recursively diffs and reverse-merges keys from second_hash into first_hash, where both
  # hashes are deeply-nested datasets of unknown depth (eg converted from complex YAML).
  # - Keys missing in second_hash are not removed from first_hash
  # - Keys present in second_hash that are not present in first_hash are added to first_hash
  def merge_keys(first_hash, second_hash)
    second_hash.each_pair do |second_key, second_value|
      first_value = first_hash[second_key]

      if second_value.is_a?(Hash) && first_value.is_a?(Hash)
        first_hash[second_key] = merge_keys(first_value, second_value)
      elsif !first_hash.key? second_key
        log JSON.pretty_generate(second_key => second_value)
        first_hash[second_key] = second_value
      end
    end

    first_hash
  end

  # Recursively diffs and reverse-merges values from second_hash into first_hash, where both
  # hashes are deeply-nested datasets of unknown depth (eg converted from complex YAML).
  # - Keys missing in second_hash are not removed from first_hash
  # - Keys present in second_hash that are not present in first_hash are not added
  # - Values in second_hash overwrite values in first_hash, if the keys are present
  #   in both hashes, and a value is present (non-blank) in second_hash
  def merge_values(first_hash, second_hash)
    first_hash.each_pair do |current_key, current_value|
      new_value = second_hash[current_key]

      if current_value.is_a?(Hash) && new_value.is_a?(Hash)
        first_hash[current_key] = merge_values(current_value, new_value)
      elsif new_value.present? && new_value != current_value
        log "#{current_key}: #{new_value}"
        first_hash[current_key] = new_value
      end
    end

    first_hash
  end

  def log(message)
    @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
    @logger.info(message)
  end
end
