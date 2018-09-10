class StoriesController < ApplicationController
  def show
    @story = Story.find_by(name: "Adventures of Me and Martha Jane")
    @chapter = @story.chapters.find_by(order: 1)
  end
end
