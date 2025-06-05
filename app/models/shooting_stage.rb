class ShootingStage < ApplicationRecord
  belongs_to :auto_run
  belongs_to :log
  has_many :stage_processes, dependent: :destroy
  has_many :log_messages, dependent: :destroy
  has_many :exposure_groups, dependent: :destroy

  def duration
    distance_of_time_in_words(run_start, run_end, true, compact: true)
  end

  def successful
    true
  end
end
