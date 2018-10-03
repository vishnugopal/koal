class AddSensitiveContentWarningToStories < ActiveRecord::Migration[5.2]
  def change
    add_column :stories, :sensitive_content_warning, :text
  end
end
