class TasksController < ApplicationController
  def create
    task_date = params[:task][:date]
    start_time = DateTime.parse("#{task_date} #{params[:task][:start_time]}")
    end_time = DateTime.parse("#{task_date} #{params[:task][:end_time]}") if params[:task][:end_time].present?

    @task = Task.new(task_params.merge(user_id: current_user.id, start_time: start_time, end_time: end_time))

    if @task.save
      render json: @task, status: :created
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end


  def edit
    @task = Task.find(params[:id])
    render json: @task
  end

  def update
    @task = Task.find(params[:id])
    if @task.update(task_params)
      render json: @task, status: :ok
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  private

  def task_params
    params.require(:task).permit(:title, :description, :start_time, :end_time)
  end
end
