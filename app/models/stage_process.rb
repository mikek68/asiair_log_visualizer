class StageProcess < ApplicationRecord
  belongs_to :log
  belongs_to :auto_run, optional: true
  belongs_to :shooting_stage, optional: true
  belongs_to :parent_stage_process, class_name: "StageProcess", foreign_key: :parent_stage_process_id, optional: true
  has_many :log_messages, dependent: :destroy
  has_many :child_stage_processes, class_name: "StageProcess", foreign_key: :parent_stage_process_id, dependent: :destroy
  has_one :user, through: :log

  scope :without_shooting_stage, -> { where(shooting_stage_id: nil) }
  scope :with_shooting_stage, -> { where.not(shooting_stage_id: nil) }

  def duration
    distance_of_time_in_words(run_start, run_end, true, compact: true)
  end
end
