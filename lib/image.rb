# Language: Ruby, Level: Level 3
# frozen_string_literal = true
# contains the definition of image class
require 'bmp'
require 'imgp'
class Image
  attr_reader :data, :height, :width, :channels
  def initialize(path)
    @data = read(path)
  end

  def read(path)
    is_bmp = 1
    if(is_bmp)
      bmp_instance = Bmp.new(path)

      a = bmp_instance.read_to_array
      bmp_instance.describe
      @height = bmp_instance.height
      @width = bmp_instance.width
      #@channels = a[0][0].length
    end
    a
  end

  def write(path)
    is_bmp = true
    if(is_bmp)
      a = Bmp.write_to_bmp(path,@data,8,0)
    end
  end


end

#DEBug
#x = Image.new('/home/harsha/imgp/librepo/rubyvision/test/rgb24.bmp')
#puts x.data.length
#puts x.data[0].length
# prints the array
#IO.write("results/image.txt", pixels.join("\n"))
#(1..x.height).each do |i|
#  puts "#{i}: ****" # Row number
#  (1..x.width).each do |j|
#    print x.data[i - 1][j - 1] # [B G R]
#    print "  "
#  end
#  puts '****'
#end
#x.write('/home/harsha/imgp/librepo/rubyvision/temp.bmp')
