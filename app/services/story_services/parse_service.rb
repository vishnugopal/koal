require_relative "../support/service"

class StoryServices::ParseService < Koal::Service
  attr_reader :author, :series, :stories

  def call(folder:, remove_folder_after_import: false)
    @folder = folder

    parser_class = "StoryServices::Parse#{source_type}Service".constantize
    @parser = parser_class.call(folder: folder)

    unless @parser.success?
      raise @parser.exception
    end

    FileUtils.remove_entry_secure(folder) if remove_folder_after_import
    completed!
  rescue Exception => e
    failed!(exception: e)
  end

  def author
    @parser.author
  end

  def series
    @parser.series
  end

  def stories
    @parser.stories
  end

  def source_type
    sol_cover_file = File.join(@folder, "cover.html")
    fel_story_pattern = "*by_Fel_c.htm"
    if File.exists? sol_cover_file
      return :SOL
    elsif Dir[File.join(@folder, fel_story_pattern)].length.nonzero?
      return :Fel
    else
      raise ArgumentError, "Folder does not correspond to a known file type"
    end
  end
end
