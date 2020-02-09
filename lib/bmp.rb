# Language: Ruby, Level: Level 3
# frozen_string_literal: true
require 'set'

# This class contains the methods to read bmp files
# It supports 1,2,4,8,16,24 bits per pixel and RLE compression

class Bmp
  # getters

  def initialize(path)
    puts "Inside bmp constructor"
    file_descriptor = IO.sysopen(path)
    @raw_data = IO.new(file_descriptor)
    @signature = @raw_data.sysread(2)
    @size = @raw_data.sysread(4).unpack('L')[0] # Because little endian format
    @raw_data.sysseek(10)
    @offset = @raw_data.sysread(4).unpack('L')[0]
    @info_header_size = @raw_data.sysread(4).unpack('L')[0]
    @width = @raw_data.sysread(4).unpack('L')[0]
    @height = @raw_data.sysread(4).unpack('L')[0]
    @planes = @raw_data.sysread(2).unpack('S')[0]
    @bits_per_pixel = @raw_data.sysread(2).unpack('S')[0]
    @numcolors = 2**@bits_per_pixel
    @compression = @raw_data.sysread(4).unpack('L')[0]
    @compressed_size = @raw_data.sysread(4).unpack('L')[0]
    @x_pixels_per_m = @raw_data.sysread(4).unpack('L')[0]
    @y_pixels_per_m = @raw_data.sysread(4).unpack('L')[0]
    @colors_used = @raw_data.sysread(4).unpack('L')[0]
    @num_of_imp_colors = @raw_data.sysread(4).unpack('L')[0]
    read_to_palette if @bits_per_pixel <= 8
    read_masks if @bits_per_pixel >= 16
    puts @raw_data.pos.to_s
  end

  def read_to_palette
    @palette = []
    (1..@colors_used).each do |i|
      b = @raw_data.sysread(1).unpack('C')[0]
      g = @raw_data.sysread(1).unpack('C')[0]
      r = @raw_data.sysread(1).unpack('C')[0]
      temp = @raw_data.sysread(1).unpack('C')
      @palette[i - 1] = [b, g, r]
      #puts "#{r},#{g},#{b}"
    end
    #IO.write("results/palette.txt", @palette.join("\n"))
  end
  attr_reader :width
  attr_reader :height
  def read_masks
    if @compression != 0
      @redmask = @raw_data.sysread(4).unpack('N')[0]
      @greenmask = @raw_data.sysread(4).unpack('N')[0]
      @bluemask = @raw_data.sysread(4).unpack('N')[0]
      @alphachannel = @raw_data.sysread(4).unpack('N')[0]
    end
  end

  def describe
    puts 'Header Data'
    puts "Signature: #{@signature}"
    puts "Size: #{@size}"
    puts "Offset: #{@offset}"
    puts 'InfoHeader Data'
    puts "Infoheader size: #{@info_header_size}"
    puts "Width: #{@width}"
    puts "Height: #{@height}"
    puts "Planes: #{@planes}"
    puts "Bits per pixel = #{@bits_per_pixel}"
    puts "Compression: #{@compression}"
    if @compression.zero?
      puts 'Compression: None'
    elsif @compression == 1
      puts 'Compression: BI_RLE8 8 bit encoding'
    elsif @compression == 2
      puts 'Compression: BI_RLE4 4 bit encoding'
    elsif @compression == 3
      puts 'Compression: BI_BITFIELDS'
    end
    puts "Compressed image size: #{@compressed_size}"
    puts "Pixel density on x-axis (per m): #{@x_pixels_per_m}"
    puts "Pixel density on y-axis (per m): #{@y_pixels_per_m}"
    puts "Used colors (in color palette): #{@colors_used}"
    puts "Number of important colors: #{@num_of_imp_colors} (0 if all are important)"
  end

  def read_to_array
    @raw_data.sysseek(@offset)
    a = Array.new(@height)

    if @bits_per_pixel <= 8
      a = read_from_palette
    elsif @bits_per_pixel > 8
      a = read_from_pixel_array
      # puts "Location of pointer after reading: #{@raw_data.pos}"
    end

    a
  end

  def read_from_palette
    a = Array.new(@height)
    if @bits_per_pixel == 1
      row_length = ((@width / 32).floor * 32 + 32) / 8
      (1..@height).each do |i|
        colors = []
        row_length_data = ''
        (1..row_length).each do
          row_length_data += @raw_data.sysread(1).unpack('C')[0].to_s
        end
        (1..@width).each do |j|
          colors[j - 1] = @palette[row_length_data[j].to_i]
        end
        a[@height - i] = colors
      end
    elsif @bits_per_pixel == 2
      (1..@height).each do |i|
        row_array = []
        row_length = ((@width / 32).floor * 32 + 32) / 8
        count = 0
        (1..row_length).each do |_j|
          break if count > @width

          byteval = @raw_data.sysread(1).unpack('C')[0]
          fourth = byteval & 3
          byteval >> 2
          third = byteval & 3
          byteval >> 2
          second = byteval & 3
          byteval >> 2
          first = byteval
          row_array.push(@palette[first])
          count += 1
          break if count >= @width

          row_array.push(@palette[second])
          count += 1
          break if count >= @width

          row_array.push(@palette[third])
          count += 1
          break if count >= @width

          row_array.push(@palette[fourth])
          count += 1
          break if count >= @width
        end
        a[@height - i] = row_array
      end
    elsif @bits_per_pixel == 4
      if @compression != 0
        a = decompress_RLE4
        return a
      end
      (1..@height).each do |i|
        row_array = []
        row_length = ((@width * 4 / 32).floor * 32 + 32) / 8
        count = 0
        (1..row_length).each do |_j|
          break if count >= @width

          byteval = @raw_data.sysread(1).unpack('C')[0]
          second = byteval & 15
          byteval >> 4
          first = byteval
          row_array.push(@palette[first])
          count += 1
          break if count >= @width

          row_array.push(@palette[second])
          count += 1
        end
        a[@height - i] = row_array
      end
    elsif @bits_per_pixel == 8
      if @compression != 0
        a = decompress_RLE8
        return a
      end
      (1..@height).each do |i|
        row_array = Array.new(@width)
        (1..@width).each do |j|
          row_array[j - 1] = @palette[@raw_data.sysread(1).unpack('C')[0]]
        end
        @raw_data.sysread((@width * 3) % 4) # zeros are appended to rows of pixels if the image width is not a multiple of 4, this ignores them.
        a[@height - i] = row_array
      end
    end
    a
  end

  def decompress_RLE4
    a = Array.new(height)
    (1..@height).each do |j|
      i = 0
      row_array = []
      len = 0
      loop do

        first_byte = @raw_data.sysread(1).unpack('C')[0]
        second_byte = @raw_data.sysread(1).unpack('C')[0]
        if first_byte != 0
          pixel_two = second_byte & 15
          pixel_one = second_byte >> 4
          rolling_array = [pixel_one, pixel_two]
          k = 0
          (1..first_byte).each do
            row_array.push(@palette[rolling_array[k]])
            k = k ^ 1
            len += 1
          end
        elsif second_byte > 2
          sz = (((second_byte + 1)>>1) + 1) & (~1)
          if second_byte%2 == 1
            temp = 0
            (1..sz).each do
              len += 2
              two_pixels =  @raw_data.sysread(1).unpack('C')[0]
              pixel_two = two_pixels & 15
              pixel_one = two_pixels >> 4
              if temp<second_byte
                row_array.push(@palette[pixel_one])
                temp += 1
              end
              if temp<second_byte
                row_array.push(@palette[pixel_two])
                temp += 1
              end
            end
          else
            (1..sz).each do
              len += 2
              two_pixels =  @raw_data.sysread(1).unpack('C')[0]
              pixel_two = two_pixels & 15
              pixel_one = two_pixels >> 4
              row_array.push(@palette[pixel_one])
              row_array.push(@palette[pixel_two])
            end
          end
        elsif second_byte == 1
          break
        end
        break if len >= @width

      end
      a[@height - j] = row_array
    end
    puts @raw_data.pos.to_s
    return a
  end

  def decompress_RLE8
    a = Array.new(@height)
    @raw_data.sysseek(@offset)
    (1..@height).each do |j|
      i = 0
      row_array = []
      len = 0
      loop do

        first_byte = @raw_data.sysread(1).unpack('C')[0]
        second_byte = @raw_data.sysread(1).unpack('C')[0]
        if first_byte != 0
          (1..first_byte).each do
            row_array.push(@palette[second_byte])
            len += 1
          end
        elsif second_byte > 2
          sz = (second_byte+1) & (~1)

          if second_byte %2 ==1
            (1..(sz-1)).each do
              len += 1
              pixel_val =  @raw_data.sysread(1).unpack('C')[0]
              row_array.push(@palette[pixel_val])
            end
            garbage = @raw_data.sysread(1).unpack('C')[0]
          else
            (1..sz).each do
              len += 1
              pixel_val =  @raw_data.sysread(1).unpack('C')[0]
              row_array.push(@palette[pixel_val])
            end
          end
        elsif second_byte == 1
          #break
        elsif second_byte == 2
          puts "Error"
        end
        break if len >= @width

      end
      a[@height - j] = row_array
    end

    return a
  end

  def read_from_pixel_array
    a = Array.new(@height)
    if @bits_per_pixel == 16 # works for rgb555 format, not rgb565
      (1..@height).each do |i|
        row_array = Array.new(@width)
        (1..@width).each do |j|
          bindata = @raw_data.sysread(2).unpack('S')[0]
          #bindata = bindata>>1
          b = (bindata<<3) & 0xf8

          g = (bindata>>2) & 0xf8
          #bindata = bindata >> 6
          r = (bindata>>7) & 0xf8
          row_array[j - 1] = [b, g, r]
        end
        @raw_data.sysread((@width * 3) % 4) # zeros are appended to rows of pixels if the image width is not a multiple of 4, this ignores them.
        a[@height - i] = row_array
      end

    elsif @bits_per_pixel == 24
      (1..@height).each do |i|
        row_array = Array.new(@width)
        (1..@width).each do |j|
          b = @raw_data.sysread(1).unpack('C')[0]
          g = @raw_data.sysread(1).unpack('C')[0]
          r = @raw_data.sysread(1).unpack('C')[0]
          row_array[j - 1] = [b, g, r]
        end
        @raw_data.sysread((@width * 3) % 4) # zeros are appended to rows of pixels if the image width is not a multiple of 4, this ignores them.
        a[@height - i] = row_array
      end
    elsif @bits_per_pixel == 32 # not tested with an image yet, maybe order of colors is wrong
      (1..@height).each do |i|
        row_array = Array.new(@width)
        (1..@width).each do |j|
          b = @raw_data.sysread(1).unpack('C')[0]
          g = @raw_data.sysread(1).unpack('C')[0]
          r = @raw_data.sysread(1).unpack('C')[0]
          alpha = @raw_data.sysread(1).unpack('C')[0]
          row_array[j - 1] = [ b, g, r, alpha] # should be changed based on requirement
        end
        @raw_data.sysread((@width * 3) % 4) # zeros are appended to rows of pixels if the image width is not a multiple of 4, this ignores them.
        a[@height - i] = row_array
      end
    end
    a
  end
  # will do once the bug is fixed

  def read_to_nmatrix
    result = [] # NMatrix.new([3, 3],dtype: :int64)
    result
  end

  def self.populate_colors(array)
    colors = Hash.new
    height = array.length
    #raise exception if empty array
    width = array[0].length
    index = 0
    #creating a hashmap of unique colors for palette
    (1...height).each do |i|
      (1...width).each do |j|
        #debug
        #if(array[i][j].class.to_s != "Array")
        #  puts "******"
        #  puts array[i][j]
        #  puts i
        #  puts j
        #  puts "******"
        #end
        if(colors.key?(array[i][j]))
          next
        else
          colors.store(array[i][j], index)
          index += 1
        end
        if(index > 255)
          print "ERROR"
          return
          #raise exception

        end
      end
    end
    colors
  end

  def self.write_to_bmp(name, array, bpp, compression_type)
    height = array.length
    #raise exception if empty array
    width = array[0].length
    filestep = ((width*3 + 3) & -(4))
    zeropad = "\0\0\0\0"
    bmp_header_size = 40

    if(bpp<=8)
      palette_size = 1024
      header_size = 14 + bmp_header_size + palette_size
      ############
      colors = populate_colors(array)
      (1..colors.length).each do |i|
        puts colors.keys[i-1].length
      end
      ####debug###
      #IO.write("palette2.txt", colors)
      ############
      file_size = height*filestep

      fileEntity = File.new(name, "w")
      if fileEntity
        size = [file_size+header_size]
        offset = [54+1024]
        x_pixels_per_m = 2000
        y_pixels_per_m = 2000
        fileEntity.syswrite([19778].pack('S')) #signature - "BM"
        fileEntity.syswrite(size.pack('L')) #size
        fileEntity.syswrite([0].pack('L')) #random 4 bytes ###check if accounting for palette
        fileEntity.syswrite(offset.pack('L')) #offset
        fileEntity.syswrite([bmp_header_size].pack('L')) #header size
        fileEntity.syswrite([width].pack('L')) #width
        fileEntity.syswrite([height].pack('L')) #height
        fileEntity.syswrite([1].pack('S')) #planes
        fileEntity.syswrite([bpp].pack('S')) #bits per pixel
        fileEntity.syswrite([compression_type].pack('L')) #compression
        fileEntity.syswrite([0].pack('L')) #compressed size
        fileEntity.syswrite([x_pixels_per_m].pack('L')) #x_pixels_per_m
        fileEntity.syswrite([y_pixels_per_m].pack('L')) #y_pixels_per_m
        fileEntity.syswrite([0].pack('L')) #number of important colors
        fileEntity.syswrite([0].pack('L')) #number of important colors
        (1..colors.length).each do |i| #writes palette
          fileEntity.syswrite([colors.keys[i-1][0]].pack('C')) #b
          fileEntity.syswrite([colors.keys[i-1][1]].pack('C')) #g
          fileEntity.syswrite([colors.keys[i-1][2]].pack('C')) #r
          #fileEntity.syswrite([colors.keys[i-1][3]].pack('C'))
          fileEntity.syswrite([0].pack('C')) #random
        end
        (1..547).each do |i| #writes palette
          fileEntity.syswrite([0].pack('C')) #random
        end
        #starts writing the pixel info
        (1...height).each do |i|
          (1...width).each do |j|
            fileEntity.syswrite([colors[array[height-i][j-1]]].pack('C'))

          end
          (1..((width*2) % 4)).each do
            fileEntity.syswrite([0].pack('C'))
          end
        end
        fileEntity.syswrite([0].pack('C'))
        fileEntity.syswrite([1].pack('C'))
      end
      print "Successfully created bmp file"
    else

    end

  end

end

#x.printcolors()



#x = Bmp.new('new8.bmp') # enter local path
#x.describe

##puts pixels.length
#puts pixels[0].length
# prints the array
#IO.write("results/image.txt", pixels.join("\n"))
#(1..x.height).each do |i|
#  #puts "#{i}: ****" # Row number
#  (1..x.width).each do |j|
#    #print pixels[i - 1][j - 1] # [B G R]
#    #print "  "
#  end
  #puts '****'
#end
#x.describe
#puts pixels.length
#puts pixels[62].length
