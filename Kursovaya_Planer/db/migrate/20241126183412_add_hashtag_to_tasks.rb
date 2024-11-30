class AddHashtagToTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :hashtag, :string
  end
end
