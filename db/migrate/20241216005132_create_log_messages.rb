class CreateLogMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :log_messages do |t|
      t.bigint :log_id
      t.bigint :plan_id
      t.bigint :auto_run_id
      t.bigint :shooting_stage_id
      t.bigint :stage_process_id
      t.string :message
      t.datetime :log_time

      t.timestamps
    end
  end
end
