# encoding: UTF-8

module Gimchi
class Korean
	# Class representing each Korean character.
	# chosung, jungsung and jongsung can be get and set.
	#
	# to_s merges components into a String.
	# to_a returns the three components.
	class Char
		attr_reader :org
		attr_reader :chosung, :jungsung, :jongsung

		def initialize kor, kchar
			raise ArgumentError('Not a korean character') unless kor.korean_char? kchar

			@kor = kor
			@cur = []
			if @kor.complete_korean_char? kchar
				c = kchar.unpack('U').first
				n = c - 0xAC00
				# '가' ~ '깋' -> 'ㄱ'
				n1 = n / (21 * 28)
				# '가' ~ '깋'에서의 순서
				n = n % (21 * 28)
				n2 = n / 28;
				n3 = n % 28;
				self.chosung = @kor.chosungs[n1]
				self.jungsung = @kor.jungsungs[n2]
				self.jongsung = ([nil] + @kor.jongsungs)[n3]
			elsif (@kor.chosungs + @kor.jongsungs).include? kchar
				self.chosung = kchar
			elsif @kor.jungsungs.include? kchar
				self.jungsung = kchar
			end

			@org = self.dup
		end

		# recombine components into korean character
		def to_s
			if chosung && jungsung
				n1, n2, n3 = 
				n1 = @kor.chosungs.index(chosung) || 0
				n2 = @kor.jungsungs.index(jungsung) || 0
				n3 = ([nil] + @kor.jongsungs).index(jongsung) || 0
				[ 0xAC00 + n1 * (21 * 28) + n2 * 28 + n3 ].pack('U')
			else
				chosung || jungsung
			end
		end

		def chosung= c
			@chosung = c && c.dup.extend(Component).tap { |e| e.kor = @kor }
		end

		def jungsung= c
			@jungsung = c && c.dup.extend(Component).tap { |e| e.kor = @kor }
		end

		def jongsung= c
			@jongsung = c && c.dup.extend(Component).tap { |e| e.kor = @kor }
		end

		# to_a returns the three components.
		def to_a
			[chosung, jungsung, jongsung]
		end

		# Check if this is a complete Korean character
		def complete?
			!partial?
		end

		# Check if this is a non-complete Korean character
		# e.g. ㅇ, ㅏ
		def partial?
			chosung.nil? || jungsung.nil?
		end

	private
		# nodoc #
		module Component
			attr_accessor :kor

			def vowel?
				kor.jungsungs.include? self
			end

			def consonant?
				self != 'ㅇ' && kor.chosungs.include?(self)
			end
		end#Component
	end#Char
end#Korean
end#Gimchi
