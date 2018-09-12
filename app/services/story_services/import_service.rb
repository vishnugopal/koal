require_relative "../support/service"

class StoryServices::ImportService < Koal::Service
  def call(folder:, remove_folder_after_import: false)
    @folder = folder

    converter_class = "StoryServices::Import#{source_type}Service".constantize
    converter_class.call(folder: folder)

    FileUtils.remove_entry_secure(folder) if remove_folder_after_import
    completed!
  rescue Exception => e
    failed!(exception: e)
  end

  def source_type
    cover_file = File.join(@folder, "cover.html")
    if File.exists? cover_file
      return :SOL
    else
      raise ArgumentError, "Folder does not correspond to a known file type"
    end
  end
end
