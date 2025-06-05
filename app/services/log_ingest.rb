class LogIngest
  attr_accessor :uploaded_files, :user

  def initialize(user:, uploaded_files:)
    @user = user
    @uploaded_files = uploaded_files
  end

  def process
    files_uploaded = 0

    uploaded_files.each do |file|
      next if user.attached_log_file_names.include?(file.original_filename)
      next unless file.original_filename.include?("Autorun_Log_")

      lf = user.log_files.attach(file)
      blob = ActiveStorage::Blob.find_by(filename: file.original_filename)
      attachment = ActiveStorage::Attachment.find_by(blob_id: blob.id)
      blob.open do |file|
        file_lines = file.readlines
        num_lines = file_lines.count
        log_line = file_lines[0]
        log_start = Time.zone.parse(log_line.split("at ")[1])
        attachment.update(num_lines: num_lines, log_start: log_start)
      end

      files_uploaded += 1
    end

    files_uploaded
  end
end
