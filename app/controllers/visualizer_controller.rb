class VisualizerController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def manage_files
    @log_files = current_user.log_files.order(log_start: :desc)
  end

  def process_file_uploads
    files_list = file_params[:upload_files].select { |f| f.present? }
    total_files = files_list.size
    files_uploaded = LogIngest.new(user: current_user, uploaded_files: files_list).process
    redirect_to visualizer_manage_files_path, success: "#{files_uploaded} Log Files uploaded successfully.  #{total_files - files_uploaded} Log Files already exist or are not Autorun Logs."
  end

  def process_file
    log_file = current_user.log_files.find(params[:id])
    Rails.logger.info("Processing file: #{log_file.filename}")
    LogReader.new(log_file: log_file, user: current_user).process
    log_file.update(processed: true)
    redirect_to visualizer_manage_files_path, success: "Log File #{log_file.filename} processed successfully."
  end

  def destroy_file
    file = current_user.log_files.find(params[:id])
    Rails.logger.info("Deleting file: #{file.filename}")
    file_name = file.filename
    file.purge
    file.destroy
    logs = current_user.logs.where(log_file_id: params[:id])
    Rails.logger.info("Deleting logs for file: #{file_name}")
    logs.destroy_all
    redirect_to visualizer_manage_files_path, success: "Log File #{file_name} and logs deleted successfully."
  end

  def file_params
    params.require(:upload_files)
  end
end
