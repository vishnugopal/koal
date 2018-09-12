class StoriesController < ApplicationController
  def new
    @story = Story.new
  end

  def create
    zipfile = params[:story][:zipfile]
    raise ActionController::RoutingError.new("Not Found") unless zipfile

    zipfile_name = zipfile.original_filename
    zipfile_path = zipfile.tempfile.to_path

    Story.load_from_zipfile(zipfile: zipfile_path,
                            source_type: :storiesonline,
                            source_format: :html,
                            story_file_name: zipfile_name)

    flash.notice = "Story successfully created"
    flash.discard
  rescue Exception => e
    logger.debug e.inspect.to_s
    flash.alert = "Story creation failed!"
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
