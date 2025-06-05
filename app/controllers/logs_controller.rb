class LogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_log_file, only: [:show_log_file, :show]

  def show_log_file
  end

  def show
    @log = Log.find(log_params[:log_id])
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

  private

  def log_params
    params.permit(:log_file_id, :log_id)
  end

  def set_log_file
    @log_file = current_user.log_files.find(log_params[:log_file_id])
    @logs = Log.where(user_id: current_user.id, log_file_id: @log_file.id).includes(:auto_runs, :plans, :shooting_stages)
  end
end
