class LogReader
  attr_accessor :log_file, :blob, :plan, :user, :log, :auto_run, :shooting_stage, :stage_processes, :exposure_group, :exposure_list

  SHOOTING_STAGE_REGEX = /^(?<date>\d*\/\d*\/\d*)\s(?<time>\d*:\d*:\d*)\sShooting\s(?<frame_count>\d*)\s(?<frame_type>\w*)\sframes, exposure\s(?<exposure>.*).\s(?<bin>.*)$/i
  STAGE_PROCESS_REGEX = /^(?<date>\d*\/\d*\/\d*)\s(?<time>\d*:\d*:\d*)\s\[(?<process>.*)\|(?<action>.*)\]\s(?<message>.*)$/i
  GUIDE_REGEX = /^(?<date>\d*\/\d*\/\d*)\s(?<time>\d*:\d*:\d*)\s\[(?<process>.*)\]\s(?<message>.*)$/i
  PLATE_SOLVE_REGEX = /^(?<date>\d*\/\d*\/\d*)\s(?<time>\d*:\d*:\d*)\sSolve\ssucceeded:\sRA:(?<ra>.*)\sDEC:(?<dec>.*)\sAngle\s=\s(?<angle>.*)\,\sStar\snumber\s=\s(?<star_count>\d*)$/i
  PLAN_MESSAGE_REGEX = /^(?<date>\d*\/\d*\/\d*)\s(?<time>\d*:\d*:\d*)\s(Plan)\s(?<plan_name>.*)\s(?<action>Start|Finish)$/i
  LOG_ENTRY_REGEX = /^(?<date>\d*\/\d*\/\d*)\s(?<time>\d*:\d*:\d*)\s(?<message>.*)$/i
  FILTER_CHANGE_REGEX = /^(?<date>\d*\/\d*\/\d*)\s(?<time>\d*:\d*:\d*)\sFilter change,\s(?<from>.*)\schange\sto\s(?<to>.*)$/i
  EXPOSURE_REGEX = /^(?<date>\d*\/\d*\/\d*)\s(?<time>\d*:\d*:\d*)\sExposure\s(?<length>.*)s\simage\s(?<image>.*)\#$/i

  def initialize(log_file:, user:)
    @log_file = log_file
    @blob = log_file.blob
    @user = user
    @stage_processes = []
    @exposure_list = []
  end

  def process
    logline = ""
    lineidx = 0

    blob.open do |log_file|
      log_file.each_line.with_index do |log_line, index|
        log_line = log_line.force_encoding("UTF-8").strip
        logline = log_line
        lineidx = index

        @log = create_log(log_line: log_line) if is_start?(log_line: log_line, start_string: "Log enabled at")
        end_log(log_line: log_line) if is_end?(log_line: log_line, end_string: "Log disabled at")

        @plan = create_plan(log_line: log_line) if is_start?(log_line: log_line, start_string: "Plan", additional_string: "Start")
        end_plan(log_line: log_line) if is_end?(log_line: log_line, end_string: "Plan", additional_string: "Finish")
        end_plan(log_line: log_line) if is_end?(log_line: log_line, end_string: "Plan", additional_string: "Pause")

        @auto_run = create_auto_run(log_line: log_line) if is_start?(log_line: log_line, start_string: "Autorun|Begin")
        auto_run.update(delayed: true, wait_time: log_line.split("Wait ")[1]) if is_autorun_wait?(log_line: log_line)
        end_auto_run(log_line: log_line) if is_end?(log_line: log_line, end_string: "Autorun|End")

        @shooting_stage = create_shooting_stage(log_line: log_line) if is_start?(log_line: log_line, start_string: "Shooting ")
        update_filter(log_line: log_line, shooting_stage: shooting_stage) if log_line.include?("Filter change")
        @exposure_group = create_exposure_group(log_line: log_line) if is_start?(log_line: log_line, start_string: "Exposure", additional_string: "image") && exposure_group.nil?
        add_exposure(log_line: log_line) if log_line.include?("Exposure") && exposure_group.present?

        @stage_processes << create_stage_process(log_line: log_line, parent_stage_process: stage_processes[-1]) if is_stage_process_start?(log_line: log_line)
        update_focus_point(log_line: log_line, stage_process: stage_processes[-1]) if log_line.include?("the focused position is")
        update_plate_solve(log_line: log_line, stage_process: stage_processes[-1]) if log_line.include?("Solve succeeded")
        end_stage_process(log_line: log_line, stage_process: stage_processes[-1]) if is_stage_process_end?(log_line: log_line)

        create_guide(log_line: log_line) if log_line.include?("[Guide]")

        record_log_message(log_line: log_line, stage_process: stage_processes[-1])

        @log = nil if is_end?(log_line: log_line, end_string: "Log disabled at")
        @plan = nil if is_end?(log_line: log_line, end_string: "Plan", additional_string: "Finish")
        @plan = nil if is_end?(log_line: log_line, end_string: "Plan", additional_string: "Pause")
        @auto_run, @shooting_stage = nil if is_end?(log_line: log_line, end_string: "Autorun|End")
        @stage_processes.pop if is_stage_process_end?(log_line: log_line)
      end
    end
  rescue => e
    Rails.logger.error("Error Message: #{e.message}")
    Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
    Rails.logger.error("Log Line: #{logline} : #{lineidx}")
  end

  private

  def is_start?(log_line:, start_string:, additional_string: nil)
    additional_string.nil? ? log_line.include?(start_string) : (log_line.include?(start_string) && log_line.include?(additional_string))
  end

  def is_end?(log_line:, end_string:, additional_string: nil)
    additional_string.nil? ? log_line.include?(end_string) : (log_line.include?(end_string) && log_line.include?(additional_string))
  end

  def is_stage_process_start?(log_line:)
    log_line.include?("|Begin]") && !log_line.include?("[Autorun|")
  end

  def is_stage_process_end?(log_line:)
    log_line.include?("|End]") && !log_line.include?("[Autorun|")
  end

  def is_autorun_wait?(log_line:)
    log_line.include?(" Wait ") && !log_line.include?("Mount") && !log_line.include?("Meridian")
  end

  def create_plan(log_line:)
    Rails.logger.debug("Creating Plan")
    log_data = parse_log_entry(log_line: log_line, regex: PLAN_MESSAGE_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    name = log_data["plan_name"]

    log_time = Time.zone.parse("#{date} #{time}")

    plan = Plan.create!(plan_start: log_time,
                        log: log,
                        name: name)

    plan
  end

  def end_plan(log_line:)
    Rails.logger.debug("Ending Plan")
    log_data = parse_log_entry(log_line: log_line, regex: LOG_ENTRY_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    message = log_data["message"]

    log_time = Time.zone.parse("#{date} #{time}")

    plan.update(plan_end: log_time)
  end

  def create_log(log_line:)
    Rails.logger.debug("Creating Log")
    log_start = Time.zone.parse(log_line.split("at ")[1])
    log = Log.create!(log_start: log_start, user: user, log_file_id: log_file.id)

    log
  end

  def create_guide(log_line:)
    log_data = parse_log_entry(log_line: log_line, regex: GUIDE_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    message = log_data["message"]

    log_time = Time.zone.parse("#{date} #{time}")

    Guide.create!(auto_run: auto_run,
                  log: log,
                  shooting_stage: shooting_stage,
                  message: message,
                  run_start: log_time)
  end

  def end_log(log_line:)
    Rails.logger.debug("Ending Log")
    log_end = Time.zone.parse(log_line.split("at ")[1])
    log.update(log_end: log_end)
  end

  def create_auto_run(log_line:)
    Rails.logger.debug("Creating AutoRun")
    log_data = parse_log_entry(log_line: log_line, regex: STAGE_PROCESS_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    message = log_data["message"]

    log_time = Time.zone.parse("#{date} #{time}")

    auto_run = AutoRun.create!(log: log,
                               plan: plan,
                               run_start: log_time,
                               name: message)

    auto_run
  end

  def end_auto_run(log_line:)
    log_data = parse_log_entry(log_line: log_line, regex: STAGE_PROCESS_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    message = log_data["message"]

    Rails.logger.debug("Ending AutoRun")
    log_time = Time.zone.parse("#{date} #{time}")

    auto_run.update(run_end: log_time, final_status: message)

    if shooting_stage.present?
      Rails.logger.debug("Ending Previous Shooting Stage")
      shooting_stage.update(run_end: log_time)
      @shooting_stage = nil
      end_exposure_group(run_end: log_time, exposure_group: exposure_group)
    end
  end

  def update_filter(log_line:, shooting_stage:)
    Rails.logger.debug("Updating Filter")
    log_data = parse_log_entry(log_line: log_line, regex: FILTER_CHANGE_REGEX)
    to = log_data["to"]

    shooting_stage.update(filter: to)
  end

  def create_shooting_stage(log_line:)
    log_data = parse_log_entry(log_line: log_line, regex: SHOOTING_STAGE_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    frame_count = log_data["frame_count"]
    frame_type = log_data["frame_type"]
    exposure = log_data["exposure"]
    bin = log_data["bin"]

    log_time = Time.zone.parse("#{date} #{time}")

    Rails.logger.debug("Creating Shooting Stage")

    if shooting_stage.present?
      Rails.logger.debug("Ending Previous Shooting Stage")
      shooting_stage.update(run_end: log_time)
      end_exposure_group(run_end: log_time, exposure_group: exposure_group)
    end

    shooting_stage = ShootingStage.create(auto_run: auto_run,
                                          log: log,
                                          frame_count: frame_count,
                                          frame_type: frame_type,
                                          exposure: exposure,
                                          bin: bin,
                                          run_start: log_time)
  end

  def create_stage_process(log_line:, parent_stage_process:)
    log_data = parse_log_entry(log_line: log_line, regex: STAGE_PROCESS_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    name = log_data["process"]
    message = log_data["message"]

    Rails.logger.debug("Creating Stage Process: #{name}")

    log_time = Time.zone.parse("#{date} #{time}")

    if exposure_group.present?
      end_exposure_group(run_end: log_time, exposure_group: exposure_group)
    end

    stage_process = name.gsub(" ", "").constantize.create!(run_start: log_time,
                                                           auto_run: auto_run,
                                                           log: log,
                                                           parent_stage_process: parent_stage_process,
                                                           shooting_stage: shooting_stage,
                                                           message: message)

    stage_process
  end

  def end_stage_process(log_line:, stage_process:)
    log_data = parse_log_entry(log_line: log_line, regex: STAGE_PROCESS_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    name = log_data["process"]
    message = log_data["message"]

    Rails.logger.debug("Ending Stage Process: #{name}")

    log_time = Time.zone.parse("#{date} #{time}")
    stage_process.update(run_end: log_time,
                         result: message)
  end

  def update_focus_point(log_line:, stage_process:)
    Rails.logger.debug("Updating Focus Position: #{log_line}")
    focus = log_line.split("the focused position is ")[1]
    stage_process.update(final_focus: focus)
  end

  def update_plate_solve(log_line:, stage_process:)
    Rails.logger.debug("Updating Plate Solve: #{log_line}")
    log_data = parse_log_entry(log_line: log_line, regex: PLATE_SOLVE_REGEX)
    ra = log_data["ra"]
    dec = log_data["dec"]
    angle = log_data["angle"]
    star_count = log_data["star_count"]

    stage_process.update(ra: ra,
                         dec: dec,
                         angle: angle,
                         star_count: star_count)
  end

  def create_exposure_group(log_line:)
    Rails.logger.debug("Creating Exposure Group: #{log_line}")
    log_data = parse_log_entry(log_line: log_line, regex: EXPOSURE_REGEX)
    date = log_data["date"]
    time = log_data["time"]
    log_time = Time.zone.parse("#{date} #{time}")

    exposure_group = ExposureGroup.create(
      shooting_stage: shooting_stage,
      run_start: log_time,
    )

    exposure_group
  end

  def end_exposure_group(run_end:, exposure_group:)
    Rails.logger.debug("Ending Exposure Group")

    exposure_group.update(
      exposure_list: exposure_list.join(","),
      exposure_count: exposure_list.size,
      run_end: run_end,
    )

    @exposure_group = nil
    @exposure_list = []
  end

  def add_exposure(log_line:)
    Rails.logger.debug("Adding Exposure: #{log_line}")
    log_data = parse_log_entry(log_line: log_line, regex: EXPOSURE_REGEX)

    exposure_list << log_data[:image]
  end

  def record_log_message(log_line:, stage_process:)
    log_time, message = nil

    if is_start?(log_line: log_line, start_string: "Log enabled at") || is_end?(log_line: log_line, end_string: "Log disabled at")
      log_time = Time.zone.parse(log_line.split("at ")[1])
      message = log_line.split(" at")[0]
    else
      date, time, message = log_line.split(" ", 3)
      log_time = Time.zone.parse("#{date} #{time}")
    end

    LogMessage.create!(log: log,
                       plan: plan,
                       auto_run: auto_run,
                       shooting_stage: shooting_stage,
                       stage_process: stage_process,
                       message: message,
                       log_time: log_time)
  end

  def parse_log_entry(log_line:, regex:)
    log_line.match(regex)
  end
end
