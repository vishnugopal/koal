module Koal::Callable
  extend ActiveSupport::Concern
  class_methods do
    def call(*args)
      new.call(*args)
    end
  end
end
