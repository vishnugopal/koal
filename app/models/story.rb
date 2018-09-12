# frozen_string_literal: true

require "nokogiri"

# :nodoc:
class Story < ApplicationRecord
  belongs_to :author
  has_many :chapters

  def slug
    name.parameterize
  end
end
