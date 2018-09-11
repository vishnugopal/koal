class StoriesController < ApplicationController
  def show
    @story = Story.find(params[:id])
    @chapter = @story.chapters.find_by(order: params[:chapter_order])
  end
end
