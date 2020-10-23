# frozen_string_literal: true

require 'yaml'

class TransifexUpdater
  def initialize
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
    new_translations = Dir.glob(Rails.root.join("config/locales/*.new"))

    new_translations.each do |new_file|
      existing_file = new_file.chomp('.new')

      merged_data = deep_diff_merge(YAML.load_file(existing_file), YAML.load_file(new_file))

      File.open(existing_file, "w") do |file|
        file.write merged_data.to_yaml(line_width: -1)
      end

      File.delete(new_file)
    end
  end

  # Recursively diffs and reverse-merges values from second_hash into first_hash, where both
  # hashes are deeply-nested datasets of unknown depth (eg converted from complex YAML).
  # - Keys missing in second_hash are not removed from first_hash
  # - Keys present in second_hash that are not present in first_hash are not added
  # - Values in second_hash overwrite values in first_hash, if the keys are present
  #   in both hashes, and a value is present (non-blank) in second_hash
  def deep_diff_merge(first_hash, second_hash)
    first_hash.each_pair do |current_key, current_value|
      new_value = second_hash[current_key]

      first_hash[current_key] = if current_value.is_a?(Hash) && new_value.is_a?(Hash)
                                  deep_diff_merge current_value, new_value
                                else
                                  new_value.present? ? new_value : current_value
                                end
    end

    first_hash
  end
end
