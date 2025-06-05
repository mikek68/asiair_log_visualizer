class LogSerializer < ActiveModel::Serializer
  # attributes :id, :log_start, :log_end
  attr_accessor :stage_process_ids_processed

  has_many :plans
  has_many :log_messages
  has_many :auto_runs

  def initialize(object, options = {})
    super
    @stage_process_ids_processed = []
  end

  def auto_runs
    build_auto_runs(object.auto_runs.without_plan).compact
  end

  def plans
    object.plans.map do |plan|
      auto_runs = build_auto_runs(plan.auto_runs).compact

      {
        id: plan.id,
        name: plan.name,
        plan_start: plan.plan_start,
        plan_end: plan.plan_end,
        auto_runs: auto_runs,
      }.compact
    end
  end

  def log_messages
    object.log_messages.order(:id).map do |log_message|
      {
        id: log_message.id,
        plan_id: log_message.plan_id,
        auto_run_id: log_message.auto_run_id,
        shooting_stage_id: log_message.shooting_stage_id,
        stage_process_id: log_message.stage_process_id,
        message: log_message.message,
        log_time: log_message.log_time,
      }.compact
    end
  end

  private

  def build_auto_runs(auto_runs)
    auto_runs.map do |auto_run|
      shooting_stages = auto_run.shooting_stages.map do |shooting_stage|
        {
          id: shooting_stage.id,
          frame_type: shooting_stage.frame_type,
          exposure: shooting_stage.exposure,
          bin: shooting_stage.bin,
          filter: shooting_stage.filter,
          run_start: shooting_stage.run_start,
          run_end: shooting_stage.run_end,
          stage_processes: build_stage_processes(shooting_stage.stage_processes).compact,
        }.compact
      end

      {
        id: auto_run.id,
        name: auto_run.name,
        final_status: auto_run.final_status,
        delayed: auto_run.delayed,
        wait_time: auto_run.wait_time,
        run_start: auto_run.run_start,
        run_end: auto_run.run_end,
        stage_processes: build_stage_processes(auto_run.stage_processes.without_shooting_stage).compact,
        shooting_stages: shooting_stages.compact,
      }.compact
    end
  end

  def build_stage_processes(stage_processes)
    stage_processes.map do |stage_process|
      next if stage_process.type == "Guide"
      next if stage_process_ids_processed.include?(stage_process.id)

      stage_process_ids_processed << stage_process.id

      {
        id: stage_process.id,
        parent_id: stage_process.parent_stage_process_id,
        name: stage_process.type,
        result: stage_process.result,
        message: stage_process.message,
        final_focus: stage_process.final_focus,
        ra: stage_process.ra,
        dec: stage_process.dec,
        angle: stage_process.angle,
        star_count: stage_process.star_count,
        successful: stage_process.successful,
        run_start: stage_process.run_start,
        run_end: stage_process.run_end,
        child_stage_processes: build_stage_processes(stage_process.child_stage_processes).compact,
      }.compact
    end
  end
end
