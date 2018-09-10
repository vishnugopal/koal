class StoriesController < ApplicationController
  def show
    @story = Story.find(params[:id])
    @chapter = @story.chapters.find_by(order: 1)
  end
end
