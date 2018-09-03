class CreateStories < ActiveRecord::Migration[5.2]
  def change
    create_table :stories do |t|
      t.string :name
      t.references :author, foreign_key: true

      t.timestamps
    end
  end
end
