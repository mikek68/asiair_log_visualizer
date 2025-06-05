class Plan < ApplicationRecord

  belongs_to :log
  has_one :user, through: :log
  has_many :auto_runs, dependent: :destroy
  has_many :log_messages, dependent: :destroy

  def duration
    distance_of_time_in_words(plan_start, plan_end, true, compact: true)
  end
end
