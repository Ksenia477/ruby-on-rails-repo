class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.datetime :start_time
      t.datetime :end_time
      t.string :priority
      t.string :status
      t.integer :user_id, index: true

      t.timestamps
    end
  end
end
