#!/usr/bin/env ruby
# coding: utf-8
# vim: ts=2 et sw=2 sts=2
#
# small/sdl/sdlmenu.rb -
# 
# Copyright © 2014 Piotr S. Staszewski 
# Visit http://www.drbig.one.pl for contact information.
#

%w{ pp sdl thread }.each {|g| require g }

FONT = 'sample.ttf'
MENU = [
  ['Menu Item One', 'sleep 5'],
  ['Menu Item Two', 'sleep 5'],
  ['Exit', nil],
]

class SDLMenu
  def initialize
    @pos = 0
    @clock = @tmp = nil
    @mutex = Mutex.new
  end

  def sdl_start
    SDL.init(SDL::INIT_VIDEO | SDL::INIT_JOYSTICK)
    @screen = SDL::Screen.open(640, 480, 16, SDL::SWSURFACE)
    SDL::WM::set_caption('SDLMenu', 'SDLMenu')
    SDL::Mouse.hide

    @joy = SDL::Joystick.open(0)

    SDL::TTF.init
    @font = SDL::TTF.open(FONT, 24)
    @font.style = SDL::TTF::STYLE_NORMAL
 end

  def sdl_stop
    @clock.kill
    @joy.close
    @font.close
    SDL.quit
  end

  def draw_menu
    @pos %= MENU.length
    y = 50
    MENU.each_with_index do |e,i|
      title = e.first
      w, h = @font.text_size(title)
      fg = @pos == i ? [0, 0, 0] : [255, 255, 255]
      bg = @pos == i ? [255, 255, 255] : [0, 0, 0]
      @screen.fill_rect(10, y, 620, h+2, bg)
      @font.draw_solid_utf8(@screen, title, 20, y+1, *fg)
      y += h+4
    end
    @mutex.synchronize { @screen.flip }
  end

  def run!
    sdl_start
    draw_menu

    @clock = Thread.new do
      while true
        now = Time.now
        str = now.strftime('%H:%M %Z')
        @screen.fill_rect(10, 10, *@tmp, [0, 0, 0]) if @tmp
        @tmp = @font.text_size(str)
        @font.draw_solid_utf8(@screen, str, 10, 10, 255, 255, 255)
        @mutex.synchronize { @screen.flip }
        sleep(60 - now.sec)
      end
    end

    while true
      pp evt = SDL::Event2.wait
      case evt
      when SDL::Event2::KeyDown, SDL::Event2::Quit
        exit(0)
      when SDL::Event2::JoyButtonUp
        if evt.button == 0
          exit unless MENU[@pos][1]
          puts MENU[@pos][1]
          break
        end
      when SDL::Event2::JoyAxis
        if evt.axis == 1
          if evt.value != 0
            @pos += 1 if evt.value > 32000
            @pos -= 1 if evt.value < 32000
          end
        end
        draw_menu
      end
    end

    sdl_stop
    exec(MENU[@pos][1] + '; ' + File.expand_path(__FILE__))
  end
end

SDLMenu.new.run! if __FILE__ == $0
