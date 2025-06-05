class CreateShootingStages < ActiveRecord::Migration[8.0]
  def change
    create_table :shooting_stages do |t|
      t.bigint :auto_run_id
      t.bigint :log_id
      t.string :frame_count
      t.string :frame_type
      t.string :exposure
      t.string :bin
      t.string :filter
      t.datetime :run_start
      t.datetime :run_end

      t.timestamps
    end
  end
end
