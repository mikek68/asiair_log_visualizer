class CreateExposureGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :exposure_groups do |t|
      t.bigint :shooting_stage_id
      t.integer :exposure_count
      t.string :exposure_list
      t.datetime :run_start
      t.datetime :run_end

      t.timestamps
    end
  end
end
