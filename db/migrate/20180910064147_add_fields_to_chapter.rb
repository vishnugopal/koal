class AddFieldsToChapter < ActiveRecord::Migration[5.2]
  def change
    change_table :chapters do |t|
      t.text :contents
      t.rename :name, :title
      t.rename :number, :order
    end
    reversible do |direction|
      direction.up do
        change_column :chapters, :order, :integer
      end
      direction.down do
        change_column :chapters, :order, :string
      end
    end
  end
end
