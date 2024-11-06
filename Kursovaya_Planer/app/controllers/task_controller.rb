class TaskController < ApplicationController
  def create
    Task.create(
      title: params[:task][:title],
      description: params[:task][:description],
      start_time: params[:task][:start_time],
      end_time: params[:task][:end_time],
      priority: params[:task][:priority],
      status: params[:task][:status],
      user_id: params[:task][:user_id]
    )
  end

  def update
    @task = Task.find(params[:id])
    @task.update(
      title: params[:task][:title],
      description: params[:task][:description],
      start_time: params[:task][:start_time],
      end_time: params[:task][:end_time],
      priority: params[:task][:priority],
      status: params[:task][:status],
      user_id: params[:task][:user_id]
    )
  end

  def destroy
    @task = Task.find(params[:id])
    @task.destroy
  end

  def show
    @task = Task.find(params[:id])
  end
end
