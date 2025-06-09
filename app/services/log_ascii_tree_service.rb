# app/services/log_ascii_tree_service.rb
class LogAsciiTreeService
  def initialize(log_file) # Changed from log to log_file
    @log_file = log_file    # Store @log_file
  end

  def generate_tree_data
    {
      name: "Log", # Changed to static string "Log"
      children: build_log_nodes(@log_file)
    }
  end

  private

  # New method to build nodes for each Log in the LogFile
  def build_log_nodes(log_file)
    nodes = []
    # Assuming LogFile has_many :logs and Log has :log_start attribute
    sorted_logs = log_file.logs.order(:log_start)
    sorted_logs.each do |log|
      nodes << {
        name: "Log (ID: #{log.id} Start: #{log.log_start.try(:strftime, '%Y-%m-%d %H:%M') || 'N/A'})",
        children: build_children_for_single_log(log) # Process children for this specific log
      }
    end
    nodes
  end

  # Renamed and refactored from build_top_level_children_nodes, now takes a log parameter
  def build_children_for_single_log(log)
    nodes = []
    # Sort Plans by plan_start
    sorted_plans = log.plans.order(:plan_start)
    sorted_plans.each do |plan|
      nodes << {
        name: "Plan (ID: #{plan.id})",
        children: build_plan_children_nodes(plan) # Pass plan object
      }
    end

    # Sort standalone AutoRuns by run_start
    auto_runs_query = log.auto_runs.where(plan_id: nil)
    sorted_standalone_auto_runs = auto_runs_query.order(:run_start)
    sorted_standalone_auto_runs.each do |auto_run|
      nodes << {
        name: "AutoRun (ID: #{auto_run.id})",
        children: build_auto_run_children_nodes(auto_run) # Pass auto_run object
      }
    end
    nodes
  end

  # build_plan_children_nodes, build_auto_run_children_nodes, etc.,
  # already take parameters and should function correctly if the passed objects are right.

  def build_plan_children_nodes(plan)
    child_nodes = []
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
    direct_stage_processes = auto_run.stage_processes.where(shooting_stage_id: nil, parent_stage_process_id: nil).to_a

    children_items = shooting_stages + direct_stage_processes
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
    direct_stage_processes_query = if shooting_stage.respond_to?(:stage_processes)
                                     shooting_stage.stage_processes.where(parent_stage_process_id: nil)
                                   else
                                     StageProcess.where(shooting_stage_id: shooting_stage.id, parent_stage_process_id: nil)
                                   end
    direct_stage_processes = direct_stage_processes_query.to_a

    children_items = exposure_groups + direct_stage_processes
    sorted_children = children_items.sort_by { |item| item.run_start || Time.at(0) }

    sorted_children.each do |item|
      if item.is_a?(ExposureGroup)
        child_nodes << {
          name: "ExposureGroup (ID: #{item.id})",
          children: []
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
    children_query = if parent_stage_process.respond_to?(:child_stage_processes)
                       parent_stage_process.child_stage_processes
                     elsif parent_stage_process.respond_to?(:children) && parent_stage_process.children.all? { |c| c.is_a?(StageProcess) }
                       parent_stage_process.children
                     else
                       StageProcess.where(parent_stage_process_id: parent_stage_process.id)
                     end

    sorted_child_processes = children_query.respond_to?(:order) ? children_query.order(:run_start) : children_query.sort_by { |cp| cp.run_start || Time.at(0) }

    sorted_child_processes.each do |child_process|
      next if child_process.type == "Guide"
      unless child_process.is_a?(StageProcess)
        next
      end
      child_nodes << {
        name: "#{child_process.type} (ID: #{child_process.id})",
        children: build_stage_process_children_nodes(child_process)
      }
    end
    child_nodes
  end
end
