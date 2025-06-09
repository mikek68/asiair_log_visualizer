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
    # Using `plan_id: nil` for standalone AutoRuns
    auto_runs_query = @log.auto_runs.where(plan_id: nil)
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
    shooting_stages = auto_run.shooting_stages.to_a
    # Direct StageProcesses for AutoRun: those not linked to a ShootingStage and are top-level
    direct_stage_processes = auto_run.stage_processes.where(shooting_stage_id: nil, parent_stage_process_id: nil).to_a

    children_items = shooting_stages + direct_stage_processes
    # Sort by run_start, handling potential nils (sorting nils first using Time.at(0))
    sorted_children = children_items.sort_by { |item| item.run_start || Time.at(0) }

    sorted_children.each do |item|
      if item.is_a?(ShootingStage)
        child_nodes << {
          name: "ShootingStage (ID: #{item.id})",
          children: build_shooting_stage_children_nodes(item)
        }
      elsif item.is_a?(StageProcess)
        next if item.type == "Guide"
        child_nodes << {
          name: "#{item.type} (ID: #{item.id})",
          children: build_stage_process_children_nodes(item)
        }
      end
    end
    child_nodes
  end

  def build_shooting_stage_children_nodes(shooting_stage)
    child_nodes = []
    exposure_groups = shooting_stage.exposure_groups.to_a

    # Direct StageProcesses for ShootingStage: those top-level within this ShootingStage
    # Assuming `shooting_stage.stage_processes` is the association for StageProcesses linked to this ShootingStage.
    # If not, it might be StageProcess.where(shooting_stage_id: shooting_stage.id, parent_stage_process_id: nil)
    direct_stage_processes_query = if shooting_stage.respond_to?(:stage_processes)
                                     shooting_stage.stage_processes.where(parent_stage_process_id: nil)
                                   else
                                     # Fallback query if direct association is not present
                                     StageProcess.where(shooting_stage_id: shooting_stage.id, parent_stage_process_id: nil)
                                   end
    direct_stage_processes = direct_stage_processes_query.to_a

    children_items = exposure_groups + direct_stage_processes
    # Sort by run_start, handling nils. Assuming ExposureGroup also has run_start.
    sorted_children = children_items.sort_by { |item| item.run_start || Time.at(0) }

    sorted_children.each do |item|
      if item.is_a?(ExposureGroup)
        child_nodes << {
          name: "ExposureGroup (ID: #{item.id})",
          children: [] # Leaf node
        }
      elsif item.is_a?(StageProcess)
        next if item.type == "Guide"
        child_nodes << {
          name: "#{item.type} (ID: #{item.id})",
          children: build_stage_process_children_nodes(item)
        }
      end
    end
    child_nodes
  end

  def build_stage_process_children_nodes(parent_stage_process)
    child_nodes = []
    # Fetch child StageProcesses, already sorted by run_start
    # Assuming `child_stage_processes` is the correct association and returns an ActiveRecord_Relation
    children_query = if parent_stage_process.respond_to?(:child_stage_processes)
                       parent_stage_process.child_stage_processes
                     elsif parent_stage_process.respond_to?(:children) && parent_stage_process.children.all? { |c| c.is_a?(StageProcess) }
                       parent_stage_process.children # Use if it's a generic association but known to contain StageProcesses
                     else
                       # Fallback query if no clear association.
                       StageProcess.where(parent_stage_process_id: parent_stage_process.id)
                     end

    # Ensure sorting is applied if children_query is an ActiveRecord::Relation
    # If it's already an array from a non-AR association, sort_by would be needed here.
    # For now, assuming .order can be chained or is part of the association definition.
    sorted_child_processes = children_query.respond_to?(:order) ? children_query.order(:run_start) : children_query.sort_by { |cp| cp.run_start || Time.at(0) }


    sorted_child_processes.each do |child_process|
      next if child_process.type == "Guide" # Skip "Guide" type
      # Ensure we are dealing with a StageProcess object, especially if 'children' association was generic
      unless child_process.is_a?(StageProcess)
        # Log a warning or handle unexpected child type if necessary
        # Rails.logger.warn "Unexpected child type in StageProcess children: #{child_process.class}"
        next
      end
      child_nodes << {
        name: "#{child_process.type} (ID: #{child_process.id})",
        children: build_stage_process_children_nodes(child_process) # Recursive call
      }
    end
    child_nodes
  end
end
