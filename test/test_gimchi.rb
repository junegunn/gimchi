# encoding: UTF-8

require 'helper'

class TestGimchi < Test::Unit::TestCase
	def test_korean_char
	end

	def test_complete_korean_char
	end

	def test_dissect
	end

	def test_read_number
	end

	def test_pronounce
	end

	def test_romanize
	end
		ko = Gimchi::Korean.new
		puts ko.romanize("으아응애애요")
		puts ko.pronounce("ㅓㅓㅓㅓ")
		puts ko.romanize("ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ")

		puts ko.read_number("0.001234")
		puts ko.read_number(100.00000000000000000000000000001234)
		puts ko.read_number(- 10_2212_3454_3029.2344308591)
		puts ko.read_number("-1945.33")
		puts ko.read_number("- 1945.33")
		puts ko.read_number("+1945.33")
		puts ko.read_number("+ 1945.33")
		puts ko.read_number(0.0000000001)

		puts ko.romanize 22123454310298340913284012840132840218400292344308591

		puts ko.pronounce("울릉도 동남쪽 뱃길따라 200리 1945년 -9월 11일")
		puts ko.romanize("울릉도 동남쪽 뱃길따라 200리 1945년 9월 84일")
		puts ko.romanize("울릉도 동남쪽 뱃길따라 200리 1945년 9월 84일", :as_pronounced => false, :slur => true)
		puts ko.pronounce("울릉도 동남쪽 뱃길따라 200리 - 1945년 9월 84일",:number => false)
		puts ko.romanize("울릉도 동남쪽 뱃길따라 200리 - 1945년 9월 84일", :as_pronounced => false, :number => false)
		puts ko.romanize("울릉도 동남쪽 뱃길따라 200리 - 1945년 9월 84일", :as_pronounced => false)
		puts ko.romanize("대관령")
		puts ko.romanize("해도지")
		puts ko.romanize("김치")

		require 'yaml'
		require 'ansi'

		cnt = 0
		s = 0
		test_set = YAML.load File.read(File.dirname(__FILE__) + '/pronunciation.yml')
		test_set.each do | k, v |
			cnt += 1

		k = k.gsub(/[-]/, '')
		t, tfs = ko.pronounce(k, :pronounce_each_char => false, :slur => k.include?(' '), :debug => true)
		if v.include? t.gsub(/\s/, '')
			r = ANSI::Code::BLUE + ANSI::Code::BOLD + v.join(' / ') + ANSI::Code::RESET if v.length > 1
			s += 1

			# next
		else
			r = ANSI::Code::RED + ANSI::Code::BOLD + v.join(' / ') + ANSI::Code::RESET
		end
		puts "#{k} => #{t} (#{ko.romanize t}) [#{tfs.join(' > ')}] #{r}"

		#break if (cnt += 1) > 30
		end
		puts "#{s} / #{cnt}"
		flunk "hey buddy, you should probably rename this file and start testing for real"
	end
end
