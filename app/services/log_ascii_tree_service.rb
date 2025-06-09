# app/services/log_ascii_tree_service.rb
class LogAsciiTreeService
  def initialize(log)
    @log = log
  end

  def generate_tree_data
    tree_data = []

    # Process Plans associated with the Log
    @log.plans.each do |plan|
      tree_data << { 'Plan' => build_plan_children(plan) }
    end

    # Process AutoRuns not associated with any Plan (direct children of Log)
    # Assuming AutoRun has a direct association with Log if not with Plan,
    # or a method like `auto_runs_without_plan` exists on the Log model.
    # If `auto_runs.without_plan` is not a direct method, this might need adjustment
    # based on actual model relationships. For now, assuming it exists.
    (@log.auto_runs.respond_to?(:without_plan) ? @log.auto_runs.without_plan : @log.auto_runs.where(plan_id: nil)).each do |auto_run|
      tree_data << { 'AutoRun' => build_auto_run_children(auto_run) }
    end

    tree_data
  end

  private

  def build_plan_children(plan)
    children = []
    plan.auto_runs.each do |auto_run|
      children << { 'AutoRun' => build_auto_run_children(auto_run) }
    end
    children
  end

  def build_auto_run_children(auto_run)
    children = []
    auto_run.shooting_stages.each do |shooting_stage|
      children << { 'ShootingStage' => build_shooting_stage_children(shooting_stage) }
    end
    # Assuming StageProcess can be a direct child of AutoRun
    auto_run.stage_processes.each do |stage_process|
      children << { 'StageProcess' => build_stage_process_children(stage_process) }
    end
    children
  end

  def build_shooting_stage_children(shooting_stage)
    children = []
    # Assuming ShootingStage has_many ExposureGroups
    # If the association is named differently, this needs to be adjusted.
    if shooting_stage.respond_to?(:exposure_groups)
      shooting_stage.exposure_groups.each do |exposure_group|
        children << { 'ExposureGroup' => [] } # ExposureGroups are leaf nodes here
      end
    end
    children
  end

  def build_stage_process_children(stage_process)
    children = []
    # StageProcess can have nested StageProcesses
    # Assuming `child_processes` or a similar association exists for nesting.
    # If StageProcess has a `parent_id` and `children` association:
    if stage_process.respond_to?(:child_processes) # Or :children, adjust as needed
      stage_process.child_processes.each do |child_process|
        children << { 'StageProcess' => build_stage_process_children(child_process) }
      end
    elsif stage_process.respond_to?(:children)
        stage_process.children.each do |child_process|
            children << { 'StageProcess' => build_stage_process_children(child_process) }
        end
    end
    # Add other potential children of StageProcess if any (e.g., specific log entries or other models)
    children
  end
end
