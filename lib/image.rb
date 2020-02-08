# Language: Ruby, Level: Level 3
# frozen_string_literal = true
# contains the definition of image class
require 'bmp'
class Image
  attr_reader :data, :height, :width, :channels
  def initialize()
    @data = []
    @height = 0
    @width = 0
    @channels = 0
  end

  def read(path)

  end

  def write(path)
  end


end
