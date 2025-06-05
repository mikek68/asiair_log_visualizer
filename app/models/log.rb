class Log < ApplicationRecord

  belongs_to :user, optional: true, foreign_key: :user_id
  has_many :auto_runs, dependent: :destroy
  has_many :log_messages, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :stage_processes, dependent: :destroy
  has_many :shooting_stages, dependent: :destroy

  def duration
    distance_of_time_in_words(log_start, log_end, true, compact: true)
  end
end
