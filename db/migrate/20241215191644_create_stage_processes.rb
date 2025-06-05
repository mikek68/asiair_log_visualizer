class CreateStageProcesses < ActiveRecord::Migration[8.0]
  def change
    create_table :stage_processes do |t|
      t.bigint :auto_run_id
      t.bigint :log_id
      t.bigint :shooting_stage_id
      t.bigint :parent_stage_process_id
      t.string :type
      t.string :message
      t.string :result
      t.string :final_focus
      t.string :ra
      t.string :dec
      t.string :angle
      t.string :star_count
      t.datetime :run_start
      t.datetime :run_end

      t.timestamps
    end
  end
end
