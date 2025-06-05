class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.bigint :log_id
      t.string :name
      t.datetime :plan_start
      t.datetime :plan_end

      t.timestamps
    end
  end
end
