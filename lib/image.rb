# Language: Ruby, Level: Level 3
# frozen_string_literal = true
# contains the definition of image class
require 'bmp'
class Image

  def initialize()
    @data = []
    @height = 0
    @width = 0
    @channels = 0
  end

  def read(path)
    
  end

  def write(path, name, format)
  end
  attr_reader :data
  attr_writer :data
  attr_reader :height
  attr_writer :height
  attr_reader :width
  attr_writer :width
  attr_reader :channels
  attr_writer :channels

end
