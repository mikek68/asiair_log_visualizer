class CreateLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :logs do |t|
      t.integer :user_id
      t.integer :log_file_id
      t.datetime :log_start
      t.datetime :log_end

      t.timestamps
    end
  end
end
