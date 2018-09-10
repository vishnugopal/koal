class AddFieldsToChapter < ActiveRecord::Migration[5.2]
  def change
    change_table :chapters do |t|
      t.text :contents
      t.rename :name, :title
      t.rename :number, :order
    end
  end
end
