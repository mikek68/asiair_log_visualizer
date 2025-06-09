require 'cli-tree'

class LogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_log_file, only: [:show_log_file, :show]

  def show_log_file
  end

  def show
    @log = Log.find(log_params[:log_id]) # This specific log is used for the Gantt chart data path
    # Service will be updated to accept log_file and logs_collection
    tree_service = LogAsciiTreeService.new(log_file: @log_file, logs_collection: @logs)
    tree_data = tree_service.generate_tree_data # This now returns a hash like { name: "Root", children: [...] }

    if tree_data.present? && tree_data[:children].present?
      # TreeNode class is directly available after require 'cli-tree'
      # as the gem uses `autoload :TreeNode, 'cli/tree/node'`
      root_treenode = TreeNode.from_h(tree_data)
      rendered_output = root_treenode.render
      if rendered_output.is_a?(Array)
        @ascii_tree = rendered_output.join("\n")
      else
        @ascii_tree = rendered_output # It's already a string
      end
    else
      @ascii_tree = "No hierarchical data to display."
    end
    # @log_data = LogSerializer.new(@log).serializable_hash.with_indifferent_access
  end

  def data
    @log = Log.find(log_params[:log_id])
    # plan = @log.plans.first if @log.plans.present?
    # Rails.logger.info("Plan Start: #{plan.plan_start.strftime("%d-%m-%Y")}")
    @log_data = {
      data: LogData.new(@log).process,
    #   [
    #     {
    #       id: "plan_id_1",
    #       text: "Plan: Horsehead Nebula",
    #       start_date: plan.plan_start.strftime("%d-%m-%Y %H:%M:%S"),
    #       end_date: plan.plan_end.strftime("%d-%m-%Y %H:%M:%S"),
    #       log_messages: "<a href='/logs/show/#{log_params[:log_file_id]}/#{log_params[:log_id]}'>View Logs</a>",
    #       progress: 1.0,
    #       color: "#000099",
    #       tool_tip_text: ["Custom Plan: Horsehead Nebula", "Start: #{plan.plan_start.strftime("%d-%m-%Y %H:%M:%S")}", "End: #{plan.plan_end.strftime("%d-%m-%Y %H:%M:%S")}"].join("<br>"),
    #       created_at: plan.created_at,
    #       open: true,
    #     },
    #     {
    #       id: "auto_run_id_1",
    #       text: "AutoRun: IC 434",
    #       start_date: (plan.plan_start + 2.minutes).strftime("%d-%m-%Y %H:%M:%S"),
    #       end_date: (plan.plan_end - 2.minutes).strftime("%d-%m-%Y %H:%M:%S"),
    #       progress: 1.0,
    #       color: "#009900",
    #       parent: "plan_id_1",
    #       created_at: plan.created_a + 2.minutes,
    #       open: true,
    #     },
    #     {
    #       id: "shooting_stage_id_1",
    #       text: "Shooting Stage",
    #       start_date: (plan.plan_start + 5.minutes).strftime("%d-%m-%Y %H:%M:%S"),
    #       end_date: (plan.plan_end - 5.minutes).strftime("%d-%m-%Y %H:%M:%S"),
    #       progress: 1.0,
    #       color: "#009900",
    #       parent: "auto_run_id_1",
    #       created_at: plan.created_at + 5.minutes,
    #       open: true,
    #     },
    #   ],
    }
    render json: @log_data
  end

  def fetch_log_messages
    class_name = params[:class_name]
    id = params[:id]

    supported_classes = ['Plan', 'AutoRun', 'ShootingStage', 'StageProcess']
    unless supported_classes.include?(class_name)
      render json: { error: "Invalid class name" }, status: :bad_request
      return
    end

    parent_model = class_name.constantize
    begin
      parent_record = parent_model.find(id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Record not found" }, status: :not_found
      return
    end

    log_messages = LogMessage.where("#{class_name.underscore}_id": id)

    order_column = LogMessage.column_names.include?('log_time') ? :log_time : :created_at
    log_messages = log_messages.order(order_column => :asc)

    render json: log_messages.map { |lm| { time: lm.send(order_column), message: lm.message } }
  end

  private

  def log_params
    params.permit(:log_file_id, :log_id)
  end

  def set_log_file
    @log_file = current_user.log_files.find(log_params[:log_file_id])
    # Eager load associations needed for the tree service and sort logs by log_start
    @logs = Log.where(user_id: current_user.id, log_file_id: @log_file.id)
                .includes(plans: { auto_runs: [{ shooting_stages: :exposure_groups }, :stage_processes] },
                          auto_runs: [{ shooting_stages: :exposure_groups }, :stage_processes] ) # Add other needed includes
                .order(:log_start)
  end
end
