class StoriesController < ApplicationController
  def index
    @stories = Story.all.order(series_name: :asc, series_book_order: :asc)
  end

  def new
    @story = Story.new
  end

  def create
    zipfile = params[:story][:zipfile]
    raise ActionController::RoutingError.new("Not Found") unless zipfile

    zipfile_name = zipfile.original_filename
    zipfile_path = zipfile.tempfile.to_path

    upload_service = StoryServices::UnzipUploadService.call(zipfile: zipfile_path,
                                                            story_file_name: zipfile_name)
    if upload_service.success?
      parse_service = StoryServices::ParseService.call(folder: upload_service.story_folder,
                                                       remove_folder_after_import: true)
      if parse_service.success?
        import_service = StoryServices::ImportService.call(author: parse_service.author,
                                                           stories: parse_service.stories)
        if import_service.success?
          flash.notice = "Story successfully created"
        else
          flash.alert = "Story import failed!"
        end
      else
        flash.alert = "Story parse failed!"
      end
    else
      flash.alert = "Story upload failed!"
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
