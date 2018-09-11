class Chapter < ApplicationRecord
  belongs_to :story

  def first?
    order == 1
  end

  def last?
    order == last_chapter_order
  end

  def last_chapter_order
    Chapter.where(story_id: story.id).order(order: :desc).first.order
  end
end
