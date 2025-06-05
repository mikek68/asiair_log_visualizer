class CreateAutoRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :auto_runs do |t|
      t.bigint :log_id
      t.bigint :plan_id
      t.string :name
      t.string :final_status
      t.boolean :delayed, default: :false
      t.string :wait_time
      t.datetime :run_start
      t.datetime :run_end

      t.timestamps
    end
  end
end
