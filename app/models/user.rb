class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  has_many_attached :log_files, dependent: :destroy
  has_many :logs, dependent: :destroy
  has_many :auto_runs, through: :logs
  has_many :log_messages, through: :logs
  has_many :plans, through: :logs
  has_many :shooting_stages, through: :auto_runs
  has_many :stage_processes, through: :auto_runs
  has_many :stage_process_messages, through: :stage_processes
  
  def attached_log_file_names
    @attached_log_file_names = log_files.map { |lf| lf.filename.to_s }
  end
end
