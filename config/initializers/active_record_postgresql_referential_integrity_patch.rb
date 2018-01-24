# A combination of fixtures and foreign key constraints requires the postgres
# user to be superuser. Otherwise an attempt to disable constraints fails.
# This got fixed in Rails 4 and this patch brings the same behaviour back to
# Rails 3. It will allow us to run the specs with a nosuperuser postgres user.
#
# See:
#  - https://github.com/matthuhiggins/foreigner/issues/61
#  - https://github.com/garysweaver/rails/commit/9bb27f7ffe3eb732df737e477cd8fc25e007f77b
if Rails::VERSION::MAJOR < 4
  class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    def disable_referential_integrity #:nodoc:
      if supports_disable_referential_integrity? then
        begin
          execute(tables.collect { |name| "ALTER TABLE #{quote_table_name(name)} DISABLE TRIGGER ALL" }.join(";"))
        rescue
          execute(tables.collect { |name| "ALTER TABLE #{quote_table_name(name)} DISABLE TRIGGER USER" }.join(";"))
        end
      end
      yield
    ensure
      if supports_disable_referential_integrity? then
        begin
          execute(tables.collect { |name| "ALTER TABLE #{quote_table_name(name)} ENABLE TRIGGER ALL" }.join(";"))
        rescue
          execute(tables.collect { |name| "ALTER TABLE #{quote_table_name(name)} ENABLE TRIGGER USER" }.join(";"))
        end
      end
    end
  end
end
