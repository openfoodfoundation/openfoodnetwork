# frozen_string_literal: true

# We got a new n8n server.
# But we still have some database rows with a URL to the old server.
class UpdateN8nUrl < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      UPDATE connected_apps
      SET data = replace(
        data::text,
        'n8n.openfoodnetwork.org.uk',
        'n8n.openfoodnetwork.org'
      )::jsonb
      WHERE data IS NOT NULL;
    SQL
  end
end
