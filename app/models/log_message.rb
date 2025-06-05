class LogMessage < ApplicationRecord
  belongs_to :log
  belongs_to :plan, optional: true
  belongs_to :auto_run, optional: true
  belongs_to :shooting_stage, optional: true
  belongs_to :stage_process, optional: true
  has_one :user, through: :log
end
