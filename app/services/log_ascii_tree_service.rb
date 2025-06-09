# app/services/log_ascii_tree_service.rb
class LogAsciiTreeService
  def initialize(log)
    @log = log
  end

  def generate_tree_data
    # This method will now return a single hash formatted for CLI::Tree::Node.from_h
    {
      name: "Log Structure (#{@log.id})",
      children: build_top_level_children_nodes
    }
  end

  private

  def build_top_level_children_nodes
    nodes = []

    # Process Plans associated with the Log
    @log.plans.each do |plan|
      nodes << {
        name: "Plan (ID: #{plan.id})", # Example: Include ID for clarity
        children: build_plan_children_nodes(plan)
      }
    end

    # Process AutoRuns not associated with any Plan
    # Adjust based on actual model relationships for fetching these auto_runs
    auto_runs_without_plan = @log.auto_runs.respond_to?(:without_plan) ? @log.auto_runs.without_plan : @log.auto_runs.where(plan_id: nil)
    auto_runs_without_plan.each do |auto_run|
      nodes << {
        name: "AutoRun (ID: #{auto_run.id})", # Example: Include ID
        children: build_auto_run_children_nodes(auto_run)
      }
    end

    nodes
  end

  def build_plan_children_nodes(plan)
    child_nodes = []
    plan.auto_runs.each do |auto_run|
      child_nodes << {
        name: "AutoRun (ID: #{auto_run.id})", # Example: Include ID
        children: build_auto_run_children_nodes(auto_run)
      }
    end
    child_nodes
  end

  def build_auto_run_children_nodes(auto_run)
    child_nodes = []
    auto_run.shooting_stages.each do |shooting_stage|
      child_nodes << {
        name: "ShootingStage (ID: #{shooting_stage.id})", # Example: Include ID
        children: build_shooting_stage_children_nodes(shooting_stage)
      }
    end
    auto_run.stage_processes.each do |stage_process|
      next if stage_process.type == "Guide" # Skip if type is "Guide"
      child_nodes << {
        name: "#{stage_process.type} (ID: #{stage_process.id})", # Use stage_process.type
        children: build_stage_process_children_nodes(stage_process)
      }
    end
    child_nodes
  end

  def build_shooting_stage_children_nodes(shooting_stage)
    child_nodes = []
    if shooting_stage.respond_to?(:exposure_groups)
      shooting_stage.exposure_groups.each do |exposure_group|
        child_nodes << {
          name: "ExposureGroup (ID: #{exposure_group.id})", # Example: Include ID
          children: [] # ExposureGroups are leaf nodes
        }
      end
    end
    child_nodes
  end

  def build_stage_process_children_nodes(stage_process)
    child_nodes = []
    # Determine the correct association for child StageProcesses
    children_association = if stage_process.respond_to?(:child_processes)
                             stage_process.child_processes
                           elsif stage_process.respond_to?(:children)
                             stage_process.children
                           else
                             [] # No known children association
                           end

    children_association.each do |child_process|
      next if child_process.type == "Guide" # Skip if type is "Guide"
      child_nodes << {
        name: "#{child_process.type} (ID: #{child_process.id})", # Use child_process.type
        children: build_stage_process_children_nodes(child_process) # Recursive call
      }
    end
    child_nodes
  end
end
