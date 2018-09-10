class AddFieldsToStory < ActiveRecord::Migration[5.2]
  def change
    change_table :stories do |t|
      t.text :intro
      t.string :copyright_notice
      t.string :description
    end
  end
end
