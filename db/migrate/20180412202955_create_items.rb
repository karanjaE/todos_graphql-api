class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.string :name
      t.boolean :done
      t.references :todo_list, foreign_key: true

      t.timestamps
    end
  end
end
