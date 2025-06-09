# app/services/log_ascii_tree_service.rb
class LogAsciiTreeService
  def initialize(log)
    @log = log
  end

  def generate_tree_data
    {
      name: "Log Structure (#{@log.id})",
      children: build_top_level_children_nodes
    }
  end

  private

  def build_top_level_children_nodes
    nodes = []
    @log.plans.each do |plan|
      nodes << {
        name: "Plan (ID: #{plan.id})",
        children: build_plan_children_nodes(plan)
      }
    end

    auto_runs_without_plan = @log.auto_runs.respond_to?(:without_plan) ? @log.auto_runs.without_plan : @log.auto_runs.where(plan_id: nil)
    auto_runs_without_plan.each do |auto_run|
      nodes << {
        name: "AutoRun (ID: #{auto_run.id})",
        children: build_auto_run_children_nodes(auto_run)
      }
    end
    nodes
  end

  def build_plan_children_nodes(plan)
    child_nodes = []
    plan.auto_runs.each do |auto_run|
      child_nodes << {
        name: "AutoRun (ID: #{auto_run.id})",
        children: build_auto_run_children_nodes(auto_run)
      }
    end
    child_nodes
  end

  def build_auto_run_children_nodes(auto_run)
    child_nodes = []
    # Add ShootingStages as direct children of AutoRun
    auto_run.shooting_stages.each do |shooting_stage|
      child_nodes << {
        name: "ShootingStage (ID: #{shooting_stage.id})",
        children: build_shooting_stage_children_nodes(shooting_stage)
      }
    end

    # Add only top-level StageProcesses as direct children of AutoRun
    # These are StageProcesses with no parent_stage_process_id within this AutoRun
    auto_run.stage_processes.where(parent_stage_process_id: nil).each do |stage_process|
      next if stage_process.type == "Guide"
      child_nodes << {
        name: "#{stage_process.type} (ID: #{stage_process.id})",
        children: build_stage_process_children_nodes(stage_process) # Recursive call for its children
      }
    end
    child_nodes
  end

  def build_shooting_stage_children_nodes(shooting_stage)
    child_nodes = []
    if shooting_stage.respond_to?(:exposure_groups)
      shooting_stage.exposure_groups.each do |exposure_group|
        child_nodes << {
          name: "ExposureGroup (ID: #{exposure_group.id})",
          children: [] # Leaf node
        }
      end
    end
    child_nodes
  end

  def build_stage_process_children_nodes(parent_stage_process)
    child_nodes = []
    # Assuming StageProcess has an association like `child_stage_processes`
    # which fetches StageProcesses where parent_stage_process_id = parent_stage_process.id
    # If not, this might need to be StageProcess.where(parent_stage_process_id: parent_stage_process.id)
    # and potentially further scoped by auto_run_id if relevant.
    # For now, relying on a direct association:
    children_to_iterate = if parent_stage_process.respond_to?(:child_stage_processes)
                            parent_stage_process.child_stage_processes
                          elsif parent_stage_process.respond_to?(:children) # A more generic fallback
                            parent_stage_process.children
                          else
                            # Fallback to direct query if no clear association.
                            # This assumes StageProcess model is accessible here.
                            # This might need to be @log.stage_processes.where(...) or similar
                            # if StageProcess is not globally queryable or needs scoping.
                            StageProcess.where(parent_stage_process_id: parent_stage_process.id)
                          end

    children_to_iterate.each do |child_process|
      next if child_process.type == "Guide"
      child_nodes << {
        name: "#{child_process.type} (ID: #{child_process.id})",
        children: build_stage_process_children_nodes(child_process) # Recursive call
      }
    end
    child_nodes
  end
end
