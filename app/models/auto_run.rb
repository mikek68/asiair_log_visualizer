class AutoRun < ApplicationRecord
  belongs_to :plan, optional: true
  belongs_to :log
  has_one :user, through: :log
  has_many :log_messages, dependent: :destroy
  has_many :shooting_stages, dependent: :destroy
  has_many :stage_processes, dependent: :destroy

  default_scope { order(id: :asc) }
  scope :without_plan, -> { where ("plan_id is null") }
  scope :with_plan, -> { where ("plan_id is not null") }

  def successful
    final_status == "Finish Autorun"
  end

  def duration
    distance_of_time_in_words(run_start, run_end, true, compact: true)
  end
end
