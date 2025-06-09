# app/services/log_ascii_tree_service.rb
class LogAsciiTreeService
  def initialize(log) # Changed back to log
    @log = log    # Store @log
  end

  def generate_tree_data
    {
      # Restored name for single log, including start time for context
      name: "Log Structure (ID: #{@log.id} Start: #{@log.log_start.try(:strftime, '%Y-%m-%d %H:%M') || 'N/A'})",
      children: build_log_children(@log) # Call method to build children of this @log
    }
  end

  private

  # This method now builds the children for the single @log
  # It combines plans and standalone autoruns, then sorts them.
  def build_log_children(log)
    nodes = []

    # Fetch plans and convert to node structure
    plan_items = log.plans.order(:plan_start).to_a.map do |plan|
      {
        item_type: :plan, # Add type for sorting and processing
        object: plan,
        sort_key: plan.plan_start || Time.at(0)
      }
    end

    # Fetch standalone AutoRuns and convert to node structure
    autorun_items = log.auto_runs.where(plan_id: nil).order(:run_start).to_a.map do |auto_run|
      {
        item_type: :auto_run, # Add type for sorting and processing
        object: auto_run,
        sort_key: auto_run.run_start || Time.at(0)
      }
    end

    # Merge and sort all top-level items (Plans and standalone AutoRuns)
    # Sorting by their respective start times (plan_start for Plan, run_start for AutoRun)
    all_top_level_items = (plan_items + autorun_items).sort_by { |i| i[:sort_key] }

    all_top_level_items.each do |item_hash|
      item_object = item_hash[:object]
      if item_hash[:item_type] == :plan
        nodes << {
          name: "Plan (ID: #{item_object.id})",
          children: build_plan_children_nodes(item_object)
        }
      elsif item_hash[:item_type] == :auto_run
        nodes << {
          name: "AutoRun (ID: #{item_object.id})", # This is a standalone AutoRun
          children: build_auto_run_children_nodes(item_object)
        }
      end
    end
    nodes
  end

  def build_plan_children_nodes(plan)
    child_nodes = []
    # AutoRuns under a plan are already sorted by their own run_start
    sorted_auto_runs = plan.auto_runs.order(:run_start)
    sorted_auto_runs.each do |auto_run|
      child_nodes << {
        name: "AutoRun (ID: #{auto_run.id})", # AutoRun under a Plan
        children: build_auto_run_children_nodes(auto_run)
      }
    end
    child_nodes
  end

  def build_auto_run_children_nodes(auto_run)
    child_nodes = []
    shooting_stages = auto_run.shooting_stages.to_a.map do |ss|
      { type: :shooting_stage, object: ss, sort_key: ss.run_start || Time.at(0) }
    end
    direct_stage_processes = auto_run.stage_processes
                                     .where(shooting_stage_id: nil, parent_stage_process_id: nil)
                                     .to_a.map do |sp|
      { type: :stage_process, object: sp, sort_key: sp.run_start || Time.at(0) }
    end

    children_items = (shooting_stages + direct_stage_processes).sort_by { |i| i[:sort_key] }

    children_items.each do |item_hash|
      item = item_hash[:object]
      if item_hash[:type] == :shooting_stage
        child_nodes << {
          name: "ShootingStage (ID: #{item.id})",
          children: build_shooting_stage_children_nodes(item)
        }
      elsif item_hash[:type] == :stage_process
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
    exposure_groups = shooting_stage.exposure_groups.to_a.map do |eg|
      # Assuming ExposureGroup has run_start; if not, use created_at or a default
      { type: :exposure_group, object: eg, sort_key: eg.run_start || Time.at(0) }
    end

    direct_stage_processes_query = if shooting_stage.respond_to?(:stage_processes)
                                     shooting_stage.stage_processes.where(parent_stage_process_id: nil)
                                   else
                                     StageProcess.where(shooting_stage_id: shooting_stage.id, parent_stage_process_id: nil)
                                   end
    direct_stage_processes = direct_stage_processes_query.to_a.map do |sp|
      { type: :stage_process, object: sp, sort_key: sp.run_start || Time.at(0) }
    end

    children_items = (exposure_groups + direct_stage_processes).sort_by { |i| i[:sort_key] }

    children_items.each do |item_hash|
      item = item_hash[:object]
      if item_hash[:type] == :exposure_group
        child_nodes << {
          name: "ExposureGroup (ID: #{item.id})",
          children: []
        }
      elsif item_hash[:type] == :stage_process
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

    # Sorting applied here
    sorted_child_processes = children_query.respond_to?(:order) ? children_query.order(:run_start) : children_query.sort_by { |cp| cp.run_start || Time.at(0) }

    sorted_child_processes.each do |child_process|
      next if child_process.type == "Guide"
      unless child_process.is_a?(StageProcess) # Should be redundant if query is specific
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
