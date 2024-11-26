class TasksController < ApplicationController
  def create
    task_date = params[:task][:date] || Date.current.to_s
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

    # Проверяем, принадлежит ли задача текущему пользователю
    if @task.user_id == current_user&.id
      task_date = params[:task][:date] || @task.start_time.to_date.to_s
      start_time = DateTime.parse("#{task_date} #{params[:task][:start_time]}")
      end_time = DateTime.parse("#{task_date} #{params[:task][:end_time]}") if params[:task][:end_time].present?

      if @task.update(task_params.merge(start_time: start_time, end_time: end_time))
        render json: @task, status: :ok
      else
        render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "You are not authorized to update this task" }, status: :forbidden
    end
  end



  def destroy
    @task = Task.find(params[:id])

    # Проверяем, принадлежит ли задача текущему пользователю
    if @task.user_id == current_user&.id
      if @task.destroy
        render json: { message: "Task deleted successfully" }, status: :ok
      else
        render json: { error: "Failed to delete task" }, status: :unprocessable_entity
      end
    else
      render json: { error: "You are not authorized to delete this task" }, status: :forbidden
    end
  end



  private

  def task_params
    params.require(:task).permit(:title, :description, :start_time, :end_time)
  end
end
