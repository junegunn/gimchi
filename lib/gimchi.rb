#!/usr/bin/env ruby
# encoding: UTF-8
# Junegunn Choi (junegunn.c@gmail.com)
# 2011/04/01-

$LOAD_PATH << '.'

require 'gimchi/korean'
require 'gimchi/char'
require 'gimchi/pronouncer'

ko = Gimchi::Korean.new
arr = ko.dissect '이것은 한글입니다.'
puts arr[4]
puts arr[4].chosung
puts arr[4].jungsung
puts arr[4].jongsung
p arr[4].to_a
