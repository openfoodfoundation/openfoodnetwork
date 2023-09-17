# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Generate Migrations for Missing Foreign Keys'
    task generate_foreign_key_migrations: :environment do
      Rails.application.eager_load!
      model_classes = filter_model_classes

      orphaned_records = generate_migrations_and_counts(model_classes)
      orphaned_records_queries, orphaned_records_counts = orphaned_records

      write_queries_to_file(orphaned_records_queries)

      summarize_counts(orphaned_records_queries, orphaned_records_counts)
    end

    def filter_model_classes
      Dir.glob(Rails.root.join('app/models/**/*.rb').to_s)
        .map { |file| File.basename(file, '.rb').camelize }
        .reject { |model| ["Gateway", "PayPalExpress", "Bogus", "BogusSimple"].include?(model) }
    end

    def generate_migrations_and_counts(model_classes)
      orphaned_records_queries = []
      orphaned_records_counts = []
      previous_models = {}

      ActiveRecord::Base.descendants.each do |model_class|
        next unless model_classes.include?(model_class.name.demodulize)

        model_class.reflect_on_all_associations(:belongs_to).each do |association|
          orphans = process_association(model_class, association, previous_models)
          if orphans
            orphaned_records_queries << orphans[0]
            orphaned_records_counts << orphans[1]
          end
        end
      end

      [orphaned_records_queries, orphaned_records_counts]
    end

    def process_association(model_class, association, previous_models)
      return if association.options[:polymorphic]

      foreign_key_table_name = determine_foreign_key_table_name(model_class, association)
      foreign_key_column = "#{association.options[:foreign_key] || association.name}_id"

      # Filter out duplicate migrations
      return if duplicate_migration?(model_class, foreign_key_table_name, previous_models)

      previous_models[model_class.table_name] ||= []
      previous_models[model_class.table_name] << foreign_key_table_name

      generate_migration(model_class, association, foreign_key_table_name)

      query = generate_orphaned_records_query(model_class, foreign_key_table_name,
                                              foreign_key_column)

      count = execute_count_query(query)

      [query, count]
    end

    def determine_foreign_key_table_name(model_class, association)
      if association.options[:class_name]
        class_name = association.options[:class_name].underscore.parameterize
        foreign_key_table_name = class_name.tableize
      else
        foreign_key_table_name = association.class_name.underscore.parameterize.tableize
        namespace = model_class.name.deconstantize

        unless association.class_name.deconstantize == namespace || namespace == "" ||
               ActiveRecord::Base.connection.table_exists?(foreign_key_table_name)
          foreign_key_table_name = "#{namespace.underscore}_#{foreign_key_table_name}"
        end
      end

      foreign_key_table_name
    end

    def generate_migration(model_class, association, foreign_key_table_name)
      migration_name = "add_foreign_key_to_#{model_class.table_name}_#{association.name}"
      migration_class_name = migration_name.camelize
      migration_file_name = "db/migrate/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_" \
                            "#{migration_name}.rb"

      File.open(migration_file_name, 'w') do |file|
        file.puts <<~MIGRATION
          class #{migration_class_name} < ActiveRecord::Migration[6.0]
            def change
              add_foreign_key :#{model_class.table_name}, :#{foreign_key_table_name}, on_delete: :cascade
            end
          end
        MIGRATION
      end

      puts "Migration generated: #{migration_file_name}"
    end

    def generate_orphaned_records_query(model_class, foreign_key_table_name, foreign_key_column)
      <<~SQL.squish
        SELECT COUNT(*) FROM #{model_class.table_name}
        LEFT JOIN #{foreign_key_table_name} ON #{model_class.table_name}.#{foreign_key_column} = #{foreign_key_table_name}.id
        WHERE #{foreign_key_table_name}.id IS NULL
      SQL
    end

    def execute_count_query(query)
      result = ActiveRecord::Base.connection.select_all(query)
      result[0]["count"].to_i if result.present?
    end

    def write_queries_to_file(queries)
      File.open("lib/tasks/data/orphaned_records_queries.sql", 'w') do |file|
        file.puts queries.join("\n\n")
      end
    end

    def summarize_counts(queries, counts)
      puts "\nSummary:"
      if counts.any?(&:positive?)
        puts "Some orphaned records were found in the following queries:"
        queries.each_with_index do |query, index|
          if counts[index] > 0
            puts "Query #{index + 1}: #{query}"
            puts "Count: #{counts[index]}"
          end
        end
      else
        puts "No orphaned records were found. Migrations are safe to proceed."
      end
    end

    def duplicate_migration?(model_class, foreign_key_table_name, previous_models)
      model_class.connection.foreign_key_exists?(model_class.table_name, foreign_key_table_name) ||
        previous_models[model_class.table_name]&.include?(foreign_key_table_name)
    end
  end
end
