class LogData
  require "dotiw"

  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :log, :tasks

  WAIT_TIME_REGEX = /^((?<hours>\d*)hr)?((?<minutes>\d*)min)?(?<seconds>\d*)s(x)?$/i

  def initialize(log)
    @log = log
    @tasks = []
  end

  def process
    process_auto_runs(log.auto_runs.without_plan) if log.auto_runs.without_plan.present?
    process_plans(log.plans) if log.plans.present?

    tasks.sort_by { |t| t[:created_at] }
  end

  private

  def process_auto_runs(auto_runs)
    auto_runs.each do |auto_run|
      build_auto_run(auto_run)
    end
  end

  def process_plans(plans)
    plans.each do |plan|
      build_plan(plan)
    end
  end

  def build_plan(plan)
    tasks << {
      id: "plan_#{plan.id}",
      text: "Plan: #{plan.name}",
      start_date: (plan.plan_start).strftime("%d-%m-%Y %H:%M:%S"),
      end_date: (plan.plan_end).strftime("%d-%m-%Y %H:%M:%S"),
      color: "#ffffff",
      textColor: "#000000",
      progress: 1.0,
      tool_tip_text: ["Custom Plan: #{plan.name}", "Duration: #{plan.duration}"].join("<br>"),
      log_messages: "<a onclick=\"logMessagesButtonClick(this);\" data-class=\"Plan\" data-id=\"#{plan.id}\" class=\"btn btn-info btn-sm p-0 ps-1 pe-1\">View Logs</button>",
      created_at: plan.created_at,
      open: true,
    }.compact

    process_auto_runs(plan.auto_runs)
  end

  def build_auto_run(auto_run)
    parent_id = auto_run.plan_id.present? ? "plan_#{auto_run.plan_id}" : nil

    tasks << {
      id: "auto_run_#{auto_run.id}",
      text: "Auto Run: #{auto_run.name}",
      start_date: (auto_run.run_start).strftime("%d-%m-%Y %H:%M:%S"),
      end_date: (auto_run.run_end).strftime("%d-%m-%Y %H:%M:%S"),
      color: auto_run.log_color,
      progress: 1.0,
      parent: parent_id,
      tool_tip_text: ["Auto Run: #{auto_run.name}", "Duration: #{auto_run.duration}"].join("<br>"),
      log_messages: "<a onclick=\"logMessagesButtonClick(this);\" data-class=\"AutoRun\" data-id=\"#{auto_run.id}\" class=\"btn btn-info btn-sm p-0 ps-1 pe-1\">View Logs</button>",
      open: true,
      created_at: auto_run.created_at,
    }.compact

    process_wait_time(auto_run) if auto_run.wait_time.present?

    process_stage_processes(auto_run.stage_processes)
    process_shooting_stages(auto_run.shooting_stages)
  end

  def process_wait_time(auto_run)
    wait_time = auto_run.wait_time.match(WAIT_TIME_REGEX)

    wait_time_start = auto_run.run_start
    wait_time_end = auto_run.run_start +
                    wait_time[:hours].to_i.send(:hours) +
                    wait_time[:minutes].to_i.send(:minutes) +
                    wait_time[:seconds].to_i.send(:seconds)
    wait_time_created_at = Time.at(auto_run.created_at.to_f + 0.001)
    wait_time_duration = distance_of_time_in_words(wait_time_start, wait_time_end, true, compact: true)

    tasks << {
      id: "wait_time_#{auto_run.id}",
      text: "Auto Run Wait",
      start_date: (wait_time_start).strftime("%d-%m-%Y %H:%M:%S"),
      end_date: (wait_time_end).strftime("%d-%m-%Y %H:%M:%S"),
      color: auto_run.wait_color,
      progress: 1.0,
      parent: "auto_run_#{auto_run.id}",
      tool_tip_text: ["Auto Run Wait", "Duration: #{wait_time_duration}"].join("<br>"),
      open: true,
      created_at: wait_time_created_at,
    }.compact
  end

  def process_stage_processes(stage_processes)
    stage_processes.each do |stage_process|
      next if stage_process.type == "Guide"
      next if tasks.pluck(:id).include?("stage_process_#{stage_process.id}")

      parent_id = if stage_process.parent_stage_process_id.present?
          "stage_process_#{stage_process.parent_stage_process_id}"
        elsif stage_process.shooting_stage_id.present?
          "shooting_stage_#{stage_process.shooting_stage_id}"
        elsif stage_process.auto_run_id.present?
          "auto_run_#{stage_process.auto_run_id}"
        else
          nil
        end

      tool_tip_text = ["Stage Process: #{stage_process.type}"]
      tool_tip_text << "Message: #{stage_process.message}" if stage_process.message.present?
      tool_tip_text << "Result: #{stage_process.result}" if stage_process.result.present?
      tool_tip_text << "Final Focus: #{stage_process.final_focus}" if stage_process.final_focus.present?
      tool_tip_text << "RA: #{stage_process.ra}" if stage_process.ra.present?
      tool_tip_text << "DEC: #{stage_process.dec}" if stage_process.dec.present?
      tool_tip_text << "Angle: #{stage_process.angle}" if stage_process.angle.present?
      tool_tip_text << "Star Count: #{stage_process.star_count}" if stage_process.star_count.present?
      tool_tip_text << "Duration: #{stage_process.duration}" if stage_process.duration.present?

      tasks << {
        id: "stage_process_#{stage_process.id}",
        text: stage_process.type,
        start_date: (stage_process.run_start).strftime("%d-%m-%Y %H:%M:%S"),
        end_date: (stage_process.run_end).strftime("%d-%m-%Y %H:%M:%S"),
        color: stage_process.log_color,
        progress: 1.0,
        parent: parent_id,
        tool_tip_text: tool_tip_text.join("<br>"),
        log_messages: "<a onclick=\"logMessagesButtonClick(this);\" data-class=\"StageProcess\" data-id=\"#{stage_process.id}\" class=\"btn btn-info btn-sm p-0 ps-1 pe-1\">View Logs</button>",
        open: true,
        created_at: stage_process.created_at,
      }.compact

      process_stage_processes(stage_process.child_stage_processes)
    end
  end

  def process_shooting_stages(shooting_stages)
    shooting_stages.each do |shooting_stage|
      next if tasks.pluck(:id).include?("shooting_stage_#{shooting_stage.id}")

      parent_id = "auto_run_#{shooting_stage.auto_run_id}"

      tool_tip_text = ["Shooting Stage"]
      tool_tip_text << "Frame Type: #{shooting_stage.frame_type}" if shooting_stage.frame_type.present?
      tool_tip_text << "Frame Count: #{shooting_stage.frame_count}" if shooting_stage.frame_count.present?
      tool_tip_text << "Exposure: #{shooting_stage.exposure}" if shooting_stage.exposure.present?
      tool_tip_text << "Bin: #{shooting_stage.bin}" if shooting_stage.bin.present?
      tool_tip_text << "Filter: #{shooting_stage.filter || "UNK"}"
      tool_tip_text << "Duration: #{shooting_stage.duration}" if shooting_stage.duration.present?

      tasks << {
        id: "shooting_stage_#{shooting_stage.id}",
        text: "Shooting Stage",
        start_date: (shooting_stage.run_start).strftime("%d-%m-%Y %H:%M:%S"),
        end_date: (shooting_stage.run_end).strftime("%d-%m-%Y %H:%M:%S"),
        color: shooting_stage.log_color,
        progress: 1.0,
        parent: parent_id,
        tool_tip_text: tool_tip_text.join("<br>"),
        log_messages: "<a onclick=\"logMessagesButtonClick(this);\" data-class=\"ShootingStage\" data-id=\"#{shooting_stage.id}\" class=\"btn btn-info btn-sm p-0 ps-1 pe-1\">View Logs</button>",
        open: true,
        created_at: shooting_stage.created_at,
      }.compact

      process_exposure_groups(shooting_stage)
    end
  end

  def process_exposure_groups(shooting_stage)
    parent_id = "shooting_stage_#{shooting_stage.id}"

    shooting_stage.exposure_groups.each do |exposure_group|
      tool_tip_text = ["Exposure Group"]
      tool_tip_text << "Frame Count: #{exposure_group.exposure_count}"
      tool_tip_text << "Frames: ##{exposure_group.exposure_list.split(",")[0]} - ##{exposure_group.exposure_list.split(",")[-1]}"
      tool_tip_text << "Filter: #{shooting_stage.filter.present? ? shooting_stage.filter : "UNK"}"
      tool_tip_text << "Duration: #{exposure_group.duration}"

      tasks << {
        id: "exposure_group_#{exposure_group.id}",
        text: "Exposure Group",
        start_date: (exposure_group.run_start).strftime("%d-%m-%Y %H:%M:%S"),
        end_date: (exposure_group.run_end).strftime("%d-%m-%Y %H:%M:%S"),
        color: "#000099",
        progress: 1.0,
        parent: parent_id,
        tool_tip_text: tool_tip_text.join("<br>"),
        open: true,
        created_at: exposure_group.created_at,
      }.compact
    end
  end
end
