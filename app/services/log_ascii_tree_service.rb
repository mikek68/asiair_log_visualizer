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
    # Sort Plans by plan_start
    sorted_plans = @log.plans.order(:plan_start)
    sorted_plans.each do |plan|
      nodes << {
        name: "Plan (ID: #{plan.id})",
        children: build_plan_children_nodes(plan)
      }
    end

    # Sort standalone AutoRuns by run_start
    auto_runs_query = @log.auto_runs.respond_to?(:without_plan) ? @log.auto_runs.without_plan : @log.auto_runs.where(plan_id: nil)
    sorted_standalone_auto_runs = auto_runs_query.order(:run_start)
    sorted_standalone_auto_runs.each do |auto_run|
      nodes << {
        name: "AutoRun (ID: #{auto_run.id})",
        children: build_auto_run_children_nodes(auto_run)
      }
    end
    nodes
  end

  def build_plan_children_nodes(plan)
    child_nodes = []
    # Sort AutoRuns under a Plan by run_start
    sorted_auto_runs = plan.auto_runs.order(:run_start)
    sorted_auto_runs.each do |auto_run|
      child_nodes << {
        name: "AutoRun (ID: #{auto_run.id})",
        children: build_auto_run_children_nodes(auto_run)
      }
    end
    child_nodes
  end

  def build_auto_run_children_nodes(auto_run)
    child_nodes = []
    # Sort ShootingStages by run_start
    sorted_shooting_stages = auto_run.shooting_stages.order(:run_start)
    sorted_shooting_stages.each do |shooting_stage|
      child_nodes << {
        name: "ShootingStage (ID: #{shooting_stage.id})",
        children: build_shooting_stage_children_nodes(shooting_stage)
      }
    end

    # Sort top-level StageProcesses by run_start
    sorted_top_level_stage_processes = auto_run.stage_processes.where(parent_stage_process_id: nil).order(:run_start)
    sorted_top_level_stage_processes.each do |stage_process|
      next if stage_process.type == "Guide"
      child_nodes << {
        name: "#{stage_process.type} (ID: #{stage_process.id})",
        children: build_stage_process_children_nodes(stage_process)
      }
    end
    child_nodes
  end

  def build_shooting_stage_children_nodes(shooting_stage)
    child_nodes = []
    if shooting_stage.respond_to?(:exposure_groups)
      # Sort ExposureGroups by run_start (or created_at if run_start is not available)
      # Assuming run_start for now.
      sorted_exposure_groups = shooting_stage.exposure_groups.order(:run_start) # Or :created_at
      sorted_exposure_groups.each do |exposure_group|
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
    children_query = if parent_stage_process.respond_to?(:child_stage_processes)
                       parent_stage_process.child_stage_processes
                     elsif parent_stage_process.respond_to?(:children)
                       parent_stage_process.children
                     else
                       StageProcess.where(parent_stage_process_id: parent_stage_process.id)
                     end

    # Sort child StageProcesses by run_start
    sorted_child_processes = children_query.order(:run_start)
    sorted_child_processes.each do |child_process|
      next if child_process.type == "Guide"
      child_nodes << {
        name: "#{child_process.type} (ID: #{child_process.id})",
        children: build_stage_process_children_nodes(child_process)
      }
    end
    child_nodes
  end
end
