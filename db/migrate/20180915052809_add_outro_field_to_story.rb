class AddOutroFieldToStory < ActiveRecord::Migration[5.2]
  def change
    change_table :stories do |t|
      t.text :outro
    end
  end
end
