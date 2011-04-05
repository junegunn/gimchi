# encoding: UTF-8

module Gimchi
class Korean
	DEFAULT_CONFIG_FILE_PATH = 
		File.dirname(__FILE__) + '/../../config/default.yml'

	attr_reader   :config
	attr_accessor :pronouncer

	# Initialize Gimchi::Korean.
	# You can override many part of the implementation with customized config file.
	def initialize config_file = DEFAULT_CONFIG_FILE_PATH
		require 'yaml'
		@config = YAML.load(File.read config_file)
		@config.freeze

		@pronouncer = Korean::Pronouncer.new(self)
	end

	# Array of chosung's
	def chosungs
		config['structure']['chosung']
	end

	# Array of jungsung's
	def jungsungs
		config['structure']['jungsung']
	end

	# Array of jongsung's
	def jongsungs
		config['structure']['jongsung']
	end

	# Checks if the given character is a korean character
	def korean_char? ch
		raise ArgumentError('Lengthy input') if ch.length > 1

		complete_korean_char?(ch) || 
			(chosungs + jungsungs + jongsungs).include?(ch)
	end

	# Checks if the given character is a "complete" korean character.
	# "Complete" Korean character must have chosung and jungsung, with optional jongsung.
	def complete_korean_char? ch
		raise ArgumentError('Lengthy input') if ch.length > 1

		# Range of Korean chracters in Unicode 2.0: AC00(가) ~ D7A3(힣)
		ch.unpack('U').all? { | c | c >= 0xAC00 && c <= 0xD7A3 }
	end

	# Splits the given string into an array of Korean::Char's and strings.
	def dissect str
		str.each_char.map { |c| 
			korean_char?(c) ? Korean::Char.new(self, c) : c
		}
	end

	# Reads a string with numbers in Korean way.
	def read_number str
		nconfig = config['number']
		
		str.to_s.gsub(/([+-]\s*)?[0-9,]*,*[0-9]+(\.[0-9]+)?(\s*.)?/) { 
			read_number_sub($&, $3)
		}
	end

	# Returns the pronunciation of the given string containing Korean characters.
	# Takes optional options hash.
	# - If :pronounce_each_char is true, each character of the string is pronounced respectively.
	# - If :slur is true, characters separated by whitespaces are treated as if they were contiguous.
	# - If :number is true, numberic parts of the string is also pronounced in Korean.
	# - :except array allows you to skip certain transformations.
	def pronounce str, options = {}
		options = {
			:pronounce_each_char => false,
			:slur => false,
			:number => true,
			:except => [],
			:debug => false
		}.merge options

		str = read_number(str) if options[:number]
		chars = dissect str

		transforms = []
		idx = -1
		while (idx += 1) < chars.length
			c = chars[idx]

			next if c.is_a?(Korean::Char) == false

			next_c = chars[idx + 1]
			next_kc = (options[:pronounce_each_char] == false &&
					   next_c.is_a?(Korean::Char) &&
					   next_c.complete?) ? next_c : nil

			transforms += @pronouncer.transform(c, next_kc, :except => options[:except])

			# Slur (TBD)
			if options[:slur] && options[:pronounce_each_char] == false && next_c =~ /\s/
				chars[(idx + 1)..-1].each_with_index do | nc, new_idx |
					next if nc =~ /\s/

					if nc.is_a?(Korean::Char) && nc.complete?
						transforms += @pronouncer.transform(c, nc, :except => options[:except])
					end

					idx = idx + 1 + new_idx - 1
					break
				end
			end
		end

		if options[:debug]
			return chars.join, transforms
		else
			chars.join
		end
	end

	# Returns the romanization (alphabetical notation) of the given Korean string.
	# http://en.wikipedia.org/wiki/Korean_romanization
	def romanize str, options = {}
		options = {
			:as_pronounced => true,
			:number => true,
			:slur => false
		}.merge options

		require 'yaml'
		rdata = config['romanization']
		post_subs = rdata["post substitution"]
		rdata = [rdata["chosung"], rdata["jungsung"], rdata["jongsung"]]

		str = pronounce str,
				:pronounce_each_char => !options[:as_pronounced],
				:number => options[:number],
				:slur => options[:slur],
				# 제1항 [붙임 1] ‘ㅢ’는 ‘ㅣ’로 소리 나더라도 ‘ui’로 적는다.
				:except => %w[rule_5_3]
		dash = rdata[0]["ㅇ"]
		romanization = ""
		(chars = str.each_char.to_a).each_with_index do | kc, cidx |
			if korean_char? kc
				Korean::Char.new(self, kc).to_a.each_with_index do | comp, idx |
					next if comp.nil?
					comp = rdata[idx][comp] || comp
					comp = comp[1..-1] if comp[0] == dash &&
							(romanization.empty? || romanization[-1] =~ /\s/ || comp[1] == 'w')
					romanization += comp
				end
			else
				romanization += kc
			end
		end

		post_subs.keys.inject(romanization) { | output, pattern |
			output.gsub(pattern, post_subs[pattern])
		}.capitalize
	end

private
	def read_number_sub num, next_char = nil
		nconfig = config['number']

		# To number
		if num.is_a? String
			num = num.gsub(/[\s,]/, '')
			raise ArgumentError.new("Invalid number format") unless num =~ /[-+]?[0-9,]*\.?[0-9]*/
			num = num.to_f == num.to_i ? num.to_i : num.to_f
		end

		# Alternative notation for integers with proper suffix
		alt = false
		if num.is_a?(Float) == false && nconfig['alt notation']['when suffix'].keys.include?(next_char.to_s.strip)
			max = nconfig['alt notation']['when suffix'][next_char.strip]['max']

			if max.nil? || num <= max
				alt = true
			end
		end

		# Sign
		if num < 0
			num = -1 * num
			negative = true
		else
			negative = false
		end

		if num.is_a? Float
			below = nconfig['decimal point']
			below = nconfig['digits'][0] + below if num < 1

			s = num.to_s
			if md = s.match(/(.*)e(.*)/)
				s = md[1].tr '.', ''
				exp = md[2].to_i
				if exp > 0
					s = s.ljust(exp + 1, '0')
				else
					s = '0.' + '0' * (-exp - 1) + s
				end
			end
			s.sub(/.*\./, '').each_char do | char |
				below += nconfig['digits'][char.to_i]
			end
			num = num.floor.to_i
		else
			below = ""
		end

		tokens = []
		unit_idx = -1
		while num > 0
			v = num % 10000

			if alt == false || unit_idx >= 0
				str = ""
				{1000 => '천',
				 100 => '백',
				 10 => '십'}.each do | u, sub_unit |
					str += (nconfig['digits'][v/u] if v/u != 1).to_s + sub_unit + ' ' if v / u > 0
					v %= u
				end
				str += nconfig['digits'][v] if v > 0

				tokens << str.sub(/ $/, '') + nconfig['units'][unit_idx += 1]
			else
				str = ""
				tenfolds = nconfig['alt notation']['tenfolds']
				digits = nconfig['alt notation']['digits']
				post_subs = nconfig['alt notation']['post substitution']

				{1000 => '천',
				 100 => '백',
				}.each do | u, sub_unit |
					str += (nconfig['digits'][v/u] if v/u != 1).to_s + sub_unit + ' ' if v / u > 0
					v %= u
				end

				str += tenfolds[(v / 10) - 1] if v / 10 > 0
				v %= 10
				str += digits[v] if v > 0

				suffix = next_char.strip
				str = str + suffix
				post_subs.each do | k, v |
					str.gsub!(k, v)
				end
				str.sub!(/#{suffix}$/, '')
				tokens << str.sub(/ $/, '') + nconfig['units'][unit_idx += 1]
			end
			num /= 10000
		end

		tokens << nconfig['negative'] if negative
		tokens.reverse.join(' ') + next_char.to_s + below
	end
end#Korean
end#Gimchi


