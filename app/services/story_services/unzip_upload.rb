require_relative "../support/service"

module StoryServices
  class UnzipUpload < Koal::Service
    attr_accessor :story_folder, :temp_folder

    def call(zipfile:, story_file_name: nil)
      @temp_folder = Dir.mktmpdir
      system("unzip #{zipfile} -d #{@temp_folder} >/dev/null")

      story_file_name = if story_file_name
                          File.basename(story_file_name, File.extname(story_file_name))
                        else
                          File.basename(zipfile, File.extname(zipfile))
                        end
      @story_folder = File.join(@temp_folder, story_file_name)
      completed!
    rescue Exception => e
      failed!(exception: e)
    end
  end
end
