# Language: Ruby, Level: Level 3
# frozen_string_literal = true
# contains the definition of image class
require 'bmp'
class Image
  attr_reader :data
  attr_reader :height
  attr_reader :width
  attr_reader :channels
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


end
