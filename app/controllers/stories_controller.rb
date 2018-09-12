class StoriesController < ApplicationController
  def new
    @story = Story.new
  end

  def create
    zipfile = params[:story][:zipfile]
    raise ActionController::RoutingError.new("Not Found") unless zipfile

    zipfile_name = zipfile.original_filename
    zipfile_path = zipfile.tempfile.to_path

    upload_service = StoryServices::UnzipUpload.call(zipfile: zipfile_path,
                                                     story_file_name: zipfile_name)
    if upload_service.success?
      import_service = StoryServices::ImportFolder.call(folder: upload_service.story_folder,
                                                        source_type: :storiesonline,
                                                        source_format: :html,
                                                        remove_folder_after_import: true)
      if import_service.success?
        flash.notice = "Story successfully created"
      else
        flash.alert = "Story creation failed!"
      end
    end
    flash.discard
  ensure
    @story = Story.new
    render :new
  end

  def show
    @story = Story.find(params[:id])
    @chapter = @story.chapters.find_by(order: params[:chapter_order])
  end
end
