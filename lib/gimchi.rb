#!/usr/bin/env ruby
# encoding: UTF-8
# Junegunn Choi (junegunn.c@gmail.com)

require 'yaml'
require 'set'
require 'gimchi/char'
require 'gimchi/pronouncer'

class Gimchi
  class << self
    def setup
      @@default ||= Gimchi.new
    end

    def Char ch
      @@default.kchar ch
    end

    [
      :korean_char?,
      :complete_korean_char?,
      :kchar,
      :kchar?,
      :read_number,
      :pronounce,
      :romanize
    ].each do |sym|
      define_method(sym) do |*arg, &b|
        @@default.send sym, *arg, &b
      end
    end
  end

  CONFIG_FILE_PATH = File.expand_path('../../config/default.yml', __FILE__)
  attr_reader :config, :chosungs, :jungsungs, :jongsungs

  # Initialize Gimchi::Korean.
  def initialize
    symbolize_keys = lambda do |val|
      case val
      when Hash
        {}.tap do |h|
          val.each do |k, v|
            k = k.gsub(' ', '_').to_sym if k =~ /[a-z0-9 ]/
            h[k] = symbolize_keys.call v
          end
        end
      when Array
        val.map { |v| symbolize_keys.call v }
      else
        val
      end
    end
    @config = symbolize_keys.call YAML.load(File.read CONFIG_FILE_PATH)

    [
      @config[:romanization][:post_substitution],
      @config[:number][:post_substitution],
      @config[:number][:alt_notation][:post_substitution]
    ].each do |r|
      r.keys.each do |k|
        r[Regexp.compile k.to_s] = r.delete k
      end
    end
    @config.freeze

    @pronouncer = Gimchi::Pronouncer.send :new, self

    @chosungs  = config[:structure][:chosung]
    @jungsungs = config[:structure][:jungsung]
    @jongsungs = config[:structure][:jongsung]
    @chosung_set  = Set[*@chosungs]
    @jungsung_set = Set[*@jungsungs]
    @jongsung_set = Set[*@jongsungs]
    @all          = @chosung_set + @jungsung_set + @jongsung_set
  end

  # @param [String] ch
  # @return [Boolean]
  def chosung? ch
    @chosung_set.include? ch
  end

  # @param [String] ch
  # @return [Boolean]
  def jungsung? ch
    @jungsung_set.include? ch
  end

  # @param [String] ch
  # @return [Boolean]
  def jongsung? ch
    @jongsung_set.include? ch
  end

  # Checks if the given character is a korean character.
  # @param [String] ch A string of size 1
  def korean_char? ch
    raise ArgumentError.new('Lengthy input') if str_length(ch) > 1

    complete_korean_char?(ch) || @all.include?(ch)
  end
  alias kchar? korean_char?

  # Checks if the given character is a "complete" korean character.
  # "Complete" Korean character must have chosung and jungsung, with optional jongsung.
  # @param [String] ch A string of size 1
  def complete_korean_char? ch
    raise ArgumentError.new('Lengthy input') if str_length(ch) > 1

    # Range of Korean chracters in Unicode 2.0: AC00(가) ~ D7A3(힣)
    ch.unpack('U').all? { | c | c >= 0xAC00 && c <= 0xD7A3 }
  end

  # Returns a Gimchi::Char object for the given Korean character.
  # @param [String] ch Korean character in String
  # @return [Gimchi::Char] Gimchi::Char instance
  def kchar ch
    Gimchi::Char.new(self, ch)
  end

  # Reads numeric expressions in Korean way.
  # @param [String, Number] str Numeric type or String containing numeric expressions
  # @return [String] Output string
  def read_number str
    str.to_s.gsub(/(([+-]\s*)?[0-9,]*,*[0-9]+(\.[0-9]+(e[+-][0-9]+)?)?)(\s*.)?/) {
      read_number_sub($1, $5)
    }
  end

  # Returns the pronunciation of the given string containing Korean characters.
  # Takes optional options hash.
  #
  # @param [String] Input string
  # @param [Hash] options Options
  # @option options [Boolean] each_char Each character of the string is pronounced respectively.
  # @option options [Boolean] slur      Strings separated by whitespaces are processed again as if they were contiguous.
  # @option options [Boolean] number    Numberic parts of the string is also pronounced in Korean.
  # @option options [Array]   except    Allows you to skip certain transformations.
  # @return [String] Output string
  def pronounce str, options = {}
    options = {
      :each_char => false,
      :slur      => false,
      :number    => true,
      :except    => [],
      :debug     => false
    }.merge options

    str = read_number(str) if options[:number]

    result, transforms = @pronouncer.send :pronounce!, str, options

    if options[:debug]
      return result, transforms
    else
      return result
    end
  end

  # Returns the romanization (alphabetical notation) of the given Korean string.
  # http://en.wikipedia.org/wiki/Korean_romanization
  # @param [String] str Input Korean string
  # @param [Hash] options Options
  # @option options [Boolean] as_pronounced If true, #pronounce is internally called before romanize
  # @option options [Boolean] number        Whether to read numeric expressions in the string
  # @option options [Boolean] slur          Same as :slur in #pronounce
  # @return [String] Output string in Roman Alphabet
  # @see Korean#pronounce
  def romanize str, options = {}
    options = {
      :as_pronounced => true,
      :number        => true,
      :slur          => false
    }.merge options

    rdata = config[:romanization]
    post_subs = rdata[:post_substitution]
    rdata = [rdata[:chosung], rdata[:jungsung], rdata[:jongsung]]

    str = pronounce str,
      :each_char => !options[:as_pronounced],
      :number    => options[:number],
      :slur      => options[:slur],
      # 제1항 [붙임 1] ‘ㅢ’는 ‘ㅣ’로 소리 나더라도 ‘ui’로 적는다.
      :except => %w[rule_5_3]
    dash = rdata[0]["ㅇ"]
    romanization = ""

    romanize_chunk = lambda do |chunk|
      chunk.each_char.map { |ch| kchar(ch) rescue ch }.each do |kc|
        kc.to_a.each_with_index do |comp, idx|
          next if comp.nil?
          comp = rdata[idx][comp] || comp
          comp = comp[1..-1] if comp[0, 1] == dash &&
              (romanization.empty? || romanization[-1, 1] =~ /\s/)
          romanization += comp
        end
      end

      return post_subs.keys.inject(romanization) { | output, pattern |
        output.gsub(pattern, post_subs[pattern])
      }
    end

    k_chunk = ""
    str.each_char do | c |
      if korean_char? c
        k_chunk += c
      else
        unless k_chunk.empty?
          romanization = romanize_chunk.call k_chunk
          k_chunk = ""
        end
        romanization += c
      end
    end
    romanization = romanize_chunk.call k_chunk unless k_chunk.empty?
    romanization
  end

private
  def str_length str
    str.length
  end

  def read_number_sub num, next_char
    nconfig = config[:number]

    if num == '0'
      return nconfig[:digits].first
    end

    num = num.gsub(',', '')
    next_char = next_char.to_s
    is_float = num.match(/[\.e]/) != nil

    # Alternative notation for integers with proper suffix
    alt = false
    if is_float == false &&
        nconfig[:alt_notation][:when_suffix].keys.include?(next_char.strip)
      max = nconfig[:alt_notation][:when_suffix][next_char.strip][:max]

      if max.nil? || num.to_i <= max
        alt = true
      end
    end

    # Sign
    sign = []
    negative = false
    if num =~ /^-/
      num = num.sub(/^-\s*/, '')
      sign << nconfig[:negative]
      negative = true
    elsif num =~ /^\+/
      num = num.sub(/^\+\s*/, '')
      sign << nconfig[:positive]
    end

    if is_float
      below = nconfig[:decimal_point]
      below = nconfig[:digits][0] + below if num.to_f < 1

      if md = num.match(/(.*)e(.*)/)
        dp = md[1].index('.')
        num = md[1].tr '.', ''
        exp = md[2].to_i

        dp += exp
        if dp > num.length
          num = num.ljust(dp, '0')
          num = num.sub(/^0+([1-9])/, "\\1")

          below = ""
        elsif dp < 0
          num = '0.' + '0' * (-dp) + num
        else
          num[dp, 1] = '.' + num[dp, 1]
        end
      end
      num.sub(/.*\./, '').each_char do | char |
        below += nconfig[:digits][char.to_i]
      end if num.include? '.'
      num = num.sub(/\..*/, '')
    else
      below = ""
    end

    tokens = []
    unit_idx = -1
    num = num.to_i
    while num > 0
      v = num % 10000

      unit_idx += 1
      if v > 0
        if alt == false || unit_idx >= 1
          str = ""
          # Cannot use hash as they're unordered in 1.8
          [[1000, '천'],
           [100,  '백'],
           [10,   '십']].each do | arr |
            u, sub_unit = arr
            str += (nconfig[:digits][v/u] if v/u != 1).to_s + sub_unit + ' ' if v / u > 0
            v %= u
          end
          str += nconfig[:digits][v] if v > 0

          tokens << str.sub(/ $/, '') + nconfig[:units][unit_idx]
        else
          str = ""
          tenfolds = nconfig[:alt_notation][:tenfolds]
          digits = nconfig[:alt_notation][:digits]
          alt_post_subs = nconfig[:alt_notation][:post_substitution]

          # Likewise.
          [[1000, '천'],
           [100,  '백']].each do |u, sub_unit|
            str += (nconfig[:digits][v/u] if v/u != 1).to_s + sub_unit + ' ' if v / u > 0
            v %= u
          end

          str += tenfolds[(v / 10) - 1] if v / 10 > 0
          v %= 10
          str += digits[v] if v > 0

          alt_post_subs.each do |p, s|
            str.gsub!(p, s)
          end if alt
          tokens << str.sub(/ $/, '') + nconfig[:units][unit_idx]
        end
      end
      num /= 10000
    end

    tokens += sign unless sign.empty?
    ret = tokens.reverse.join(' ') + below + next_char
    nconfig[:post_substitution].each do |p, s|
      ret.gsub!(p, s)
    end
    ret
  end
end#Gimchi

require 'gimchi/patch_1.8'

Gimchi.setup
