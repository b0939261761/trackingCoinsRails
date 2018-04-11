class ArInternalMetadata < ActiveRecord::Migration[5.1]
  def change
    table_name = :ar_internal_metadata

    change_column_default(table_name, :created_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' })
    change_column_default(table_name, :updated_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' })

    reversible do |direction|
      direction.up do
        execute <<-SQL.squish
          CREATE OR REPLACE FUNCTION update_at_timestamp() RETURNS trigger AS $$
            BEGIN
              NEW.updated_at := current_timestamp;
              RETURN NEW;
            END;
          $$ LANGUAGE plpgsql;

          CREATE TRIGGER #{table_name}_update_at
            BEFORE UPDATE ON #{table_name}
              FOR EACH ROW EXECUTE PROCEDURE update_at_timestamp()
        SQL
      end

      direction.down do
        execute <<-SQL
          DROP FUNCTION IF EXISTS update_at_timestamp() CASCADE;
        SQL
      end
    end
  end
end
