#!/usr/bin/env ruby
# encoding: UTF-8
# Junegunn Choi (junegunn.c@gmail.com)

require 'gimchi/korean'
require 'gimchi/char'
require 'gimchi/pronouncer'

if RUBY_VERSION =~ /^1\.8\./
  require 'gimchi/patch_1.8' 
end
