# Chapter7
require "library/treemap"
require "library/BoundsIntegrator"

$:.push("library")
require "json"

$root_item     = nil
$rollover_item = nil
$tagged_item   = nil
$zoom_item     = nil
$mod_times     = []
$zoom_bounds   = nil

class Chapter7 < Processing::App
  include_package "treemap"

  def setup
    size(700, 700)
    rect_mode(CORNERS)
    smooth
#    no_stroke
    frame_rate(30)

    $zoom_bounds = BoundsIntegrator.new(0, 0, width, height)

    @font = create_font("sansSerif", 13)
    text_font(@font)

    set_root("artist_data.json")
  end

  def set_root(path)
    data = JSON.parse(load_strings(path).join("\n"))
    item = FolderItem.new(nil, "music library", 1739161.0, 0, "root", data["artists"])
    item.setBounds(0, 0, width, height)
    item.contents_visible = true
    item.zoom_in
    item.update_colors
    $root_item = item
  end

  def draw
    background(0)
    $zoom_bounds.update

    $rollover_item = nil
    $tagged_item   = nil

    $root_item.draw           unless $root_item.nil?
    $rollover_item.draw_title unless $rollover_item.nil?
    $tagged_item.draw_tag     unless $tagged_item.nil?
  end

  def mouse_pressed
    $zoom_item._mouse_pressed unless $zoom_item.nil?
  end

# FileItem
  class FileItem < SimpleMapItem
    attr_accessor :name, :path, :hue, :c, :parent

    def initialize(parent, name, size, order, type = "song")
      super()

      @text_padding = 8

      @parent = parent
      @order  = order
      @name   = name
      @type   = type

      self.size = size

      @c          = nil
      @hue        = 0
      @brightness = 0
      @darkness   = 0
    end

    def update_colors
      @hue = map(@order, 0, @parent.getItems.length, 0, 360) unless @parent.nil?
      @brightness = 100 #rand(40) + 40
      color_mode(HSB, 360, 100, 100)

      alpha = 150

      if @parent == $zoom_item then
        @c = color(@hue, 80, 80, alpha)
      elsif !@parent.nil? then
        @c = color(@parent.hue, 80, @brightness, alpha)
      end

      color_mode(RGB, 255)
      @c
    end

    def calc_box
      @box_left   = $zoom_bounds.span_x(x,     0, width);
      @box_right  = $zoom_bounds.span_x(x + w, 0, width);
      @box_top    = $zoom_bounds.span_y(y,     0, height);
      @box_bottom = $zoom_bounds.span_y(y + h, 0, height);
      [@box_left, @box_top, @box_right, @box_bottom]
    end

    def draw
      _draw
    end

    def _draw
      self.calc_box
      fill(@c)
      rect(@box_left, @box_top, @box_right, @box_bottom)

      if self.text_fits then
        self.draw_title
      elsif self.mouse_inside then
        $rollover_item = self
      end
    end

    def draw_title
      fill(255, 200)
      middle_x = (@box_left + @box_right) / 2
      middle_y = (@box_top + @box_bottom) / 2

      if middle_x > 0 and middle_x < width and middle_y > 0 and middle_y < height then
        if @box_left + text_width(@name) + @text_padding * 2 > width then
          text_align(RIGHT)
          text(@name, width - @text_padding, @box_bottom, - @text_padding)
        else
          text_align(LEFT)
          text(@name, @box_left + @text_padding, @box_bottom, - @text_padding)
        end
      end
    end

    def text_fits
      wide = text_width(@name) + @text_padding * 2
      high = text_ascent + text_descent + @text_padding * 2
      ((@box_right - @box_left) > wide) and ((@box_bottom - @box_top) > high)
    end

    def mouse_inside
      mouse_x > @box_left and mouse_x < @box_right and
      mouse_y > @box_top and mouse_y < @box_bottom
    end

    def _mouse_pressed
      if mouse_inside then
        case mouse_button
        when LEFT
          @parent.zoom_in
          # play
          if self.song? and @parent == $zoom_item then
            exec_file = File.dirname(File.expand_path(__FILE__)) + "/play_itunes.js"
            `cscript "#{exec_file}" "#{@parent.parent.name}" "#{@parent.name}" "#{@name}"`
          end
          return true
        when RIGHT
          @parent.zoom_out      if r = @parent == $zoom_item
          @parent.hide_contents unless r
          return true
        end
      end

      false
    end

    def root?
      @type == "root"
    end

    def artist?
      @type == "artist"
    end

    def album?
      @type == "album"
    end

    def song?
      @type == "song"
    end
  end

# FolderItem
  class FolderItem < FileItem
    include Java::Treemap::MapModel
    attr_accessor :contents_visible, :hue, :c, :items

    def initialize(parent, name, size, order, type, children)
      super(parent, name, size, order, type)

      @algorithm        = Java::Treemap::SquarifiedLayout.new
      @contents_visible = false
      @layout_valid     = false
      @items            = get_children(children)
    end

    def get_children(children)
      items = []
      case @type
      when "root"
        children.each{|k, v|
          items.push(FolderItem.new(self, k, v["size"], items.length, "artist", v["albums"]))
        }
      when "artist"
        children.each{|k, v|
          items.push(FolderItem.new(self, k, v, items.length, "album", {}))
        }
      when "album"
        children.each{|k, v|
          items.push(FileItem.new(self, k, v, items.length, "song"))
        }
      end
      items
    end

    def update_colors
      super
      @items.each {|item| item.update_colors }
    end

    def check_layout
      unless @layout_valid then
        @algorithm.layout(self, self.bounds) unless @items.empty?
        @layout_valid = true
      end
    end

    def _mouse_pressed
      if self.album? and @items.empty? then
        exec_file = File.dirname(File.expand_path(__FILE__)) + "/get_tracks.js"
        result = `cscript #{exec_file} "#{@parent.name}" "#{@name}"`
        @items = get_children(JSON.parse(result))
        @algorithm.layout(self, self.bounds)
        self.update_colors
      end

      if self.mouse_inside then
        if @contents_visible then
          for i in (0 .. @items.length - 1)
            return true if @items[i]._mouse_pressed
          end
        elsif !@items.empty? then
          case mouse_button
          when LEFT
            self.show_contents if r = @parent == $zoom_item
            @parent.zoom_in    unless r
          when RIGHT
            @parent.zoom_out      if r = @parent == $zoom_item
            @parent.hide_contents unless r
          end
          return true
        end
      end

      false
    end

    def zoom_out
      unless @parent.nil? then
        @items.each {|item| item.hide_contents unless item.song? }
        @parent.zoom_in
      end
    end

    def zoom_in
      $zoom_item = self
      $zoom_bounds.target(self.x, self.y, self.w, self.h)
    end

    def show_contents
      @contents_visible = true
    end

    def hide_contents
      @contents_visible = false unless @parent.nil?
    end

    def draw
      self.check_layout
      self.calc_box

      # draw artwork
      if self.album? and ($zoom_item == @parent or $zoom_item == self) then
        if @img.nil? then
          filename = "#{@parent.name}_#{@name}"
          imgs = Dir.glob("data/artwork/#{filename}.*")
	      @img = load_image("artwork/#{filename}" + File.extname(imgs[0])) unless imgs.empty?
	    end

        image(@img, @box_left - 1, @box_top - 1,
                    @box_right - @box_left - 2, @box_bottom - @box_top - 2) unless @img.nil?
      end

      @items.each {|item| item.draw } if @contents_visible
      _draw unless @contents_visible

      # show tag
      $tagged_item = self if @contents_visible and
                             self.mouse_inside and
                             @parent == $zoom_item

      @darkness = self.mouse_inside ? @darkness * 0.05 : (150 - @darkness) * 0.05

      if @parent == $zoom_item then
        color_mode(RGB, 255)
        fill(0, @darkness)
        rect(@box_left, @box_top, @box_right, @box_bottom)
      end
    end

    def draw_title
      super if @contents_visible
    end

    def draw_tag
      box_height = text_ascent + @text_padding * 2

      if @box_bottom - @box_top > box_height * 2 then
        fill(0, 128)
        rect(@box_left, @box_top, @box_right, @box_top + box_height)
        fill(255)
        text_align(LEFT, TOP)
        text(@name, @box_left + @text_padding, @box_top + @text_padding)
      elsif @box_top > box_height then
        fill(0, 128)
        rect(@box_left, @box_top - box_height, @box_right, @box_top)
        fill(255)
        text(@name, @box_left + @text_padding, @box_top - @text_padding)
      elsif @box_bottom + box_height < height then
        fill(0, 128)
        rect(@box_left, @box_bottom, @box_right, @box_top + box_height)
        fill(255)
        text_align(LEFT, TOP)
        text(@name, @box_left + @text_padding, @box_top + @text_padding)
      end
    end

    def getItems
      @items.to_java(FileItem)
    end
  end
end

def p_once(s)
  unless $p_called then
    $p_called = true
    p s
  end
end

Chapter7.new :title => "Chapter7"