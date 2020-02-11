# Language: Ruby, Level: Level 3
require 'image'
class Imgproc

  # Converts RGB image to grayscale
  def self.bgr_to_grayscale(img)
    height = img.data.length
    width = img.data[0].length
    #assuming the image has RGB channels
    (1..height).each do |i|
      (1..width).each do |j|
        val = (img.data[i][j][0] + img.data[i][j][1] + img.data[i][j][2]) / 3
        img.data[i][j][0] = val
        img.data[i][j][1] = val
        img.data[i][j][2] = val
      end
    end
    img
  end

  # Converts RGB to Hue Saturation and Value
  def self.bgr_to_hsv(img)
    height = img.data.length
    width = img.data[0].length
    (1..height).each do |i|
      (1..width).each do |j|
        img.data[i][j] = hsv_util(img.data[i][j])
      end
    end
    img
  end
  #utility function for bgr_to_hsv
  def self.bgr_to_hsv_util(array)
    r_ = (array[0]/255.0)
    g_ = (array[1]/255.0)
    b_ = (array[2]/255.0)
    c_max = array.max
    c_min = array.min
    delta = c_max-c_min
    #Hue calculation
    if(delta == 0)
      h = 0
    elsif (c_max == r_)
      h = 60*(((g_- b_)/delta)%6)
    elsif (c_max == g)
      h = 60*(((b_- r_)/delta)+2)
    else
      h = 60*(((r_-g_)/delta)+4)
    end
    #saturation
    if(c_max == 0)
      s = 0
    else
      s = delta/c_max
    end
    #value
    v = cmax
    return [h,s,v]
  end

  def self.blur(img, blurtype)

  end

  def self.dilate(img)

  end

  def self.erode(img)

  end

  def self.scale(img)

  end

  def self.rotate(img)

  end

  def self.kernel_transform(img, kernel)

  end

  def self.alpha_removal(img)

  end


end
