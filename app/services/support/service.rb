require_relative "callable"

class Koal::Service
  include Koal::Callable

  attr_accessor :exception

  def completed!
    @success = true
    self
  end

  def failed!(exception: nil)
    @exception = exception
    @success = false
    self
  end

  def success?
    @success == true
  end
end
