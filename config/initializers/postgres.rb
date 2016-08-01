module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SchemaStatements
      def drop_table_cascade(table_name, options = {})
        execute "DROP TABLE #{quote_table_name(table_name)} CASCADE"
      end
    end
  end
end
