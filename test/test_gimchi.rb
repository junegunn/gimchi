# encoding: UTF-8

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'helper'
require 'yaml'
require 'ansi'


class TestGimchi < Test::Unit::TestCase
	def test_korean_char
		ko = Gimchi
		assert_equal true, ko.korean_char?('ㄱ')  # true
		assert_equal true, ko.kchar?('ㄱ')  # true
		assert_equal true, ko.korean_char?('ㅏ')  # true
		assert_equal true, ko.korean_char?('가')  # true
		assert_equal true, ko.korean_char?('값')  # true
		assert_equal true, ko.kchar?('값')  # true

		assert_equal false, ko.korean_char?('a')   # false
		assert_equal false, ko.korean_char?('1')   # false
		assert_raise(ArgumentError) { ko.korean_char?('두자') }
		assert_raise(ArgumentError) { ko.kchar?('두자') }
	end

  def test_kchar
    kc = Gimchi::Char('한')
    assert_equal Gimchi::Char, kc.class
    assert_equal "ㅎ", kc.chosung
    assert_equal "ㅏ", kc.jungsung
    assert_equal "ㄴ", kc.jongsung
    assert_equal ["ㅎ", "ㅏ", "ㄴ"], kc.to_a
    assert_equal "한", kc.to_s
    assert_equal true, kc.complete?
    assert_equal false, kc.partial?

		assert_raise(ArgumentError) { Gimchi::Char('한글') }
		assert_raise(ArgumentError) { Gimchi::Char('A') }

    assert_equal true, Gimchi::Char("ㅏ").partial?
  end

	def test_complete_korean_char
		ko = Gimchi

		assert_equal false, ko.complete_korean_char?('ㄱ') # false
		assert_equal false, ko.complete_korean_char?('ㅏ') # false
		assert_equal true, ko.complete_korean_char?('가') # true
		assert_equal true, ko.complete_korean_char?('값') # true

		assert_equal false, ko.korean_char?('a')   # false
		assert_equal false, ko.korean_char?('1')   # false
		assert_raise(ArgumentError) { ko.korean_char?('두자') }
	end

  def test_dissect
		arr = '이것은 Hangul 입니다.'.each_char.map { |ch|
      (Gimchi::Char(ch) rescue [ch]).to_a
    }.flatten.compact

    assert_equal ["ㅇ", "ㅣ", "ㄱ", "ㅓ", "ㅅ", "ㅇ", "ㅡ", "ㄴ", " ",
                  "H", "a", "n", "g", "u", "l", " ", "ㅇ", "ㅣ", "ㅂ",
                  "ㄴ", "ㅣ", "ㄷ", "ㅏ", "."], arr
  end

	def test_convert
		ko = Gimchi

		arr = '이것은 한글입니다.'.each_char.map { |ch|
      Gimchi::Char(ch) rescue ch
    }
		# [이, 것, 은, " ", 한, 글, 입, 니, 다, "."]

		assert_equal 10, arr.length
		assert_equal Gimchi::Char, arr[0].class
		assert_equal Gimchi::Char, arr[1].class
		assert_equal Gimchi::Char, arr[2].class

		ch = arr[2]
		assert_equal 'ㅇ', ch.chosung
		assert_equal 'ㅡ', ch.jungsung
		assert_equal 'ㄴ', ch.jongsung
    assert_equal "은(ㅇ/ㅡ/ㄴ)", ch.inspect

		ch.chosung = 'ㄱ'
		ch.jongsung = 'ㅁ'
		assert_equal '금', ch.to_s
		assert_equal 3, ch.to_a.length

		ch.jongsung = nil
		assert_equal '그', ch.to_s
		assert_equal 2, ch.to_a.compact.length
		assert_equal true, ch.complete?
		assert_equal false, ch.partial?

		ch.chosung = nil
		assert_equal 1, ch.to_a.compact.length
		assert_equal false, ch.complete?
		assert_equal true, ch.partial?
		assert_equal 'ㅡ', ch.to_s

		ch.jungsung = nil
		assert_equal 0, ch.to_a.compact.length
		assert_equal false, ch.complete?
		assert_equal true, ch.partial?
		assert_equal '', ch.to_s

		assert_raise(ArgumentError) { ch.chosung = 'ㅡ' }
		assert_raise(ArgumentError) { ch.chosung = 'ㄳ' }
		assert_raise(ArgumentError) { ch.jungsung = 'ㄱ' }
		assert_raise(ArgumentError) { ch.jongsung = 'ㅠ' }
	end

	def test_read_number
		ko = Gimchi
		assert_equal "영", ko.read_number(0)
		assert_equal "일", ko.read_number(1)
		assert_equal "구", ko.read_number(9)
		assert_equal "천 구백 구십 구", ko.read_number(1999)
		assert_equal "마이너스 백점일이삼", ko.read_number(- 100.123)
		assert_equal "오백 삼십 일억 구천 백 십만 육백 칠십 팔점삼이일사오육칠",
				ko.read_number("53,191,100,678.3214567")
		assert_equal "영점영영영영영일이삼사오", ko.read_number("1.2345e-06")
		assert_equal "일해 이천 삼백 사십 오경", ko.read_number("1.2345e+20")
		assert_equal "플러스 일해 이천 삼백 사십 오경", ko.read_number("+ 1.2345e+20")
		assert_equal "마이너스 일해 이천 삼백 사십 오경", ko.read_number("- 1.2345e+20")
		assert_equal "만 십 이점삼", ko.read_number("100.123e+2")
		assert_equal "십만 십 이점삼", ko.read_number("1000.123e+2")
		assert_equal "백 일만 십 이점삼", ko.read_number("10100.123e+2")
		assert_equal "천 십 이점삼", ko.read_number("10.123e+2")
		assert_equal "십점영", ko.read_number("10.0")
		assert_equal "플러스 십점영", ko.read_number("+ 10.0")

		# 나이, 시간, 개수, 명 ( -살, -시, -개, -명 )
		assert_equal "나는 이십", ko.read_number("나는 20")
		assert_equal "나는 스무살", ko.read_number("나는 20살")
		assert_equal "나는 스물네살", ko.read_number("나는 24살")
		assert_equal "스무개", ko.read_number("20개")
		assert_equal "스무 명", ko.read_number("20 명")
		assert_equal "이십 칠점일살", ko.read_number("27.1살")
		assert_equal "너는 열세 살", ko.read_number("너는 13 살")
		assert_equal "백 서른두명", ko.read_number("132명")
		assert_equal "이천 오백 아흔아홉개", ko.read_number("2,599개")
		assert_equal "지금은 일곱시 삼십분", ko.read_number("지금은 7시 30분")
	end

	def test_pronounce
		ko = Gimchi
		cnt = 0
		s = 0
		test_set = YAML.load File.read(File.dirname(__FILE__) + '/pronunciation.yml')
		test_set.each do | k, v |
			cnt += 1
			k = k.gsub(/[-]/, '')

			t1, tfs1 = ko.pronounce(k, :each_char => false, :slur => true, :debug => true)
			t2, tfs2 = ko.pronounce(k, :each_char => false, :slur => false, :debug => true)

			path = ""
			if (with_slur = v.include?(t1.gsub(/\s/, ''))) || v.include?(t2.gsub(/\s/, ''))
				r = ANSI::Code::BLUE + ANSI::Code::BOLD + v.join(' / ') + ANSI::Code::RESET if v.length > 1
				path = (with_slur ? tfs1 : tfs2).map { |e| e.sub 'rule_', '' }.join(' > ')
				t = with_slur ? t1 : t2
				s += 1
			else
				r = ANSI::Code::RED + ANSI::Code::BOLD + v.join(' / ') + ANSI::Code::RESET
				t = [t1, t2].join ' | '
			end
			puts "#{k} => #{t} (#{ko.romanize t, :as_pronounced => false}) [#{path}] #{r}"
		end
		puts "#{s} / #{cnt}"
		# FIXME
		assert s >= 411
	end

	def test_romanize_preserve_non_korean
		ko = Gimchi
		assert_equal 'ttok-kkateun kkk', ko.romanize('똑같은 kkk')
	end

	def test_romanize
		ko = Gimchi

		cnt = 0
		s = 0
		test_set = YAML.load File.read(File.dirname(__FILE__) + '/romanization.yml')
		test_set.each do | k, v |
			cnt += 1
			rom = ko.romanize k.sub(/\[.*/, '')
			if rom.downcase.gsub(/[\s-]/, '') == v.downcase.gsub(/\(.*\)/, '').gsub(/[\s-]/, '')
				r = ANSI::Code::BLUE + ANSI::Code::BOLD + rom + ANSI::Code::RESET
				s += 1
			else
				r = ANSI::Code::RED + ANSI::Code::BOLD + rom + ANSI::Code::RESET
			end
			puts "#{k} => #{r} [#{v}]"
		end
		puts "#{s} / #{cnt}"
		# FIXME
		assert s >= 63
	end
end
