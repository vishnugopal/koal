class AddSeriesFieldsToStory < ActiveRecord::Migration[5.2]
  def change
    change_table :stories do |t|
      t.text :series_name
      t.text :series_book_title
      t.integer :series_book_order
    end
  end
end
