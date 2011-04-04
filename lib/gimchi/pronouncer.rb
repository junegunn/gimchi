# encoding: UTF-8

module Gimchi
class Korean
private
	# Partial implementation of Korean pronouncement pronunciation rules specified in
	# http://http://www.korean.go.kr/
	class Pronouncer
		attr_reader :applied

		def initialize(korean)
			@korean = korean
			@pconfig = korean.config['pronouncer']
			@applied = []
		end

		def transform kc, next_kc, options = {}
			options = {
				:except => []
			}.merge options
			@applied.clear
			kc.chosung = 'ㅇ' if kc.chosung.nil?
			kc.jungsung = 'ㅡ' if kc.jungsung.nil?

			if next_kc.nil?
				rule_single kc
			else
				not_todo = []
				blocking_rule = @pconfig['transformation']['blocking rule']
				@pconfig['transformation']['sequence'].each do | rule |
					next if not_todo.include?(rule) || options[:except].include?(rule)

					if self.send(rule, kc, next_kc)
						@applied << rule
						not_todo += blocking_rule[rule] if blocking_rule.has_key?(rule)
					end
				end
			end
			@applied
		end

	private
		# shortcut
		def fortis_map
			@korean.config['structure']['fortis map']
		end

		# shortcut
		def double_consonant_map
			@korean.config['structure']['double consonant map']
		end

		def rule_single kc
			rule_5_1 kc, nil
			rule_5_3 kc, nil

			if kc.jongsung
				kc.jongsung = @pconfig['jongsung sound'][kc.jongsung]
			end
		end

		# 제5항: ‘ㅑ ㅒ ㅕ ㅖ ㅘ ㅙ ㅛ ㅝ ㅞ ㅠ ㅢ’는 이중 모음으로 발음한다.
		#  다만 1. 용언의 활용형에 나타나는 ‘져, 쪄, 쳐’는 [저, 쩌, 처]로 발음한다.
		#  다만 3. 자음을 첫소리로 가지고 있는 음절의 ‘ㅢ’는 [ㅣ]로 발음한다.
		def rule_5_1 kc, next_kc
			if %w[져 쪄 쳐].include? kc.to_s
				kc.jungsung = 'ㅓ'

				true
			end
		end

		def rule_5_3 kc, next_kc
			if kc.jungsung == 'ㅢ' && kc.org.chosung.consonant?
				kc.jungsung = 'ㅣ'

				true
			end
		end

		# 제9항: 받침 ‘ㄲ, ㅋ’, ‘ㅅ, ㅆ, ㅈ, ㅊ, ㅌ’, ‘ㅍ’은 어말 또는 자음 앞에서
		# 각각 대표음 [ㄱ, ㄷ, ㅂ]으로 발음한다.
		def rule_9 kc, next_kc
			map = {
				%w[ㄲ ㅋ] => 'ㄱ',
				%w[ㅅ ㅆ ㅈ ㅊ ㅌ] => 'ㄷ',
				%w[ㅍ] => 'ㅂ'
			}
			if map.keys.flatten.include?(kc.jongsung) && (next_kc.nil? || next_kc.chosung.consonant?)
				kc.jongsung = map[ map.keys.find { |e| e.include? kc.jongsung } ]

				true
			end
		end

		# 제10항: 겹받침 ‘ㄳ’, ‘ㄵ’, ‘ㄼ, ㄽ, ㄾ’, ‘ㅄ’은 어말 또는 자음 앞에서
		# 각각 [ㄱ, ㄴ, ㄹ, ㅂ]으로 발음한다.
		def rule_10 kc, next_kc
			map = {
				%w[ㄳ] => 'ㄱ',
				%w[ㄵ] => 'ㄴ',
				%w[ㄼ ㄽ ㄾ] => 'ㄹ',
				%w[ㅄ] => 'ㅂ'
			}
			if map.keys.flatten.include?(kc.jongsung) && (next_kc.nil? || next_kc.chosung.consonant?)
				# Exceptions
				if next_kc && (
					   (kc.to_s == '밟' && next_kc.chosung.consonant?) ||
					   (kc.to_s == '넓' && next_kc && %w[적 죽 둥].include?(next_kc.org.to_s))) # PATCH
					kc.jongsung = 'ㅂ'
				else
					kc.jongsung = map[ map.keys.find { |e| e.include? kc.jongsung } ]
				end

				true
			end
		end

		# 제11항: 겹받침 ‘ㄺ, ㄻ, ㄿ’은 어말 또는 자음 앞에서 각각 [ㄱ, ㅁ, ㅂ]으로 발음한다.
		def rule_11 kc, next_kc
			map = {
				'ㄺ' => 'ㄱ',
				'ㄻ' => 'ㅁ',
				'ㄿ' => 'ㅂ'
			}
			if map.keys.include?(kc.jongsung) && (next_kc.nil? || next_kc.chosung.consonant?)
				# 다만, 용언의 어간 말음 ‘ㄺ’은 ‘ㄱ’ 앞에서 [ㄹ]로 발음한다.
				# - 용언 여부 판단은?: 중성으로 판단 (PATCH)
				if next_kc && kc.jongsung == 'ㄺ' &&
					next_kc.org.chosung == 'ㄱ' &&
					%w[맑 얽 섥 밝 늙 묽 넓].include?(kc.to_s) # PATCH
					kc.jongsung = 'ㄹ'
				else
					kc.jongsung = map[kc.jongsung]
				end

				true
			end
		end

		# 제12항: 받침 ‘ㅎ’의 발음은 다음과 같다.
		#  1. ‘ㅎ(ㄶ, ㅀ)’ 뒤에 ‘ㄱ, ㄷ, ㅈ’이 결합되는 경우에는, 뒤 음절 첫소리와
		#  합쳐서 [ㅋ, ㅌ, ㅊ]으로 발음한다.
		#  [붙임 1]받침 ‘ㄱ(ㄺ), ㄷ, ㅂ(ㄼ), ㅈ(ㄵ)’이 뒤 음절 첫소리 ‘ㅎ’과
		#  결합되는 경우에도, 역시 두 음을 합쳐서 [ㅋ, ㅌ, ㅍ, ㅊ]으로 발음한다.
		#  [붙임 2]규정에 따라 ‘ㄷ’으로 발음되는 ‘ㅅ, ㅈ, ㅊ, ㅌ’의 경우에도 이에 준한다.
		#
		#  2. ‘ㅎ(ㄶ, ㅀ)’ 뒤에 ‘ㅅ’이 결합되는 경우에는, ‘ㅅ’을 [ㅆ]으로 발음한다.
		#
		#  3. ‘ㅎ’ 뒤에 ‘ㄴ’이 결합되는 경우에는, [ㄴ]으로 발음한다.
		#   [붙임]‘ㄶ, ㅀ’ 뒤에 ‘ㄴ’이 결합되는 경우에는, ‘ㅎ’을 발음하지 않는다.
		#
		#  4. ‘ㅎ(ㄶ, ㅀ)’ 뒤에 모음으로 시작된 어미나 접미사가 결합되는 경우에는, ‘ㅎ’을 발음하지 않는다.
		def rule_12 kc, next_kc
			return if next_kc.nil?

			map_12_1 = {
				'ㄱ' => 'ㅋ',
				'ㄷ' => 'ㅌ',
				'ㅈ' => 'ㅊ' }
				if %w[ㅎ ㄶ ㅀ].include?(kc.jongsung) 
					# 12-1
					if map_12_1.keys.include?(next_kc.chosung)
						next_kc.chosung = map_12_1[next_kc.chosung]
						kc.jongsung = (dc = double_consonant_map[kc.jongsung]) && dc.first

						# 12-2
					elsif next_kc.chosung == 'ㅅ'
						kc.jongsung = (dc = double_consonant_map[kc.jongsung]) && dc.first
						next_kc.chosung = 'ㅆ'

						# 12-3
					elsif next_kc.chosung == 'ㄴ'
						if dc = double_consonant_map[kc.jongsung]
							kc.jongsung = dc.first
						else
							kc.jongsung = 'ㄴ'
						end

						# 12-4
					elsif next_kc.chosung == 'ㅇ'
						kc.jongsung = (dc = double_consonant_map[kc.jongsung]) && dc.first
					end

					true
				end

				# 12-1 붙임
				if next_kc.chosung == 'ㅎ'
					map_jongsung = {
						# 붙임 1
						'ㄱ' => [nil,  'ㅋ'],
						'ㄺ' => ['ㄹ', 'ㅋ'],
						'ㄷ' => [nil,  'ㅌ'],
						'ㅂ' => [nil,  'ㅍ'],
						'ㄼ' => ['ㄹ', 'ㅍ'],
						'ㅈ' => [nil,  'ㅊ'],
						'ㄵ' => ['ㄴ', 'ㅊ'],

						# 붙임 2
						'ㅅ' => [nil, 'ㅌ'],
						#'ㅈ' => [nil, 'ㅌ'], # FIXME: 붙임2의 모순
						'ㅊ' => [nil, 'ㅌ'],
						'ㅌ' => [nil, 'ㅌ'],
					}
					if trans1 = map_jongsung[kc.jongsung]
						kc.jongsung = trans1.first
						next_kc.chosung = trans1.last

						true
					end
				end
		end

		# 제13항: 홑받침이나 쌍받침이 모음으로 시작된 조사나 어미, 접미사와
		# 결합되는 경우에는, 제 음가대로 뒤 음절 첫소리로 옮겨 발음한다.
		def rule_13 kc, next_kc
			return if kc.jongsung.nil? || kc.jongsung == 'ㅇ' || next_kc.nil? || next_kc.chosung != 'ㅇ'
			next_kc.chosung = kc.jongsung
			kc.jongsung = nil

			true
		end
		# 제14항: 겹받침이 모음으로 시작된 조사나 어미, 접미사와 결합되는 경우에는,
		# 뒤엣것만을 뒤 음절 첫소리로 옮겨 발음한다.(이 경우, ‘ㅅ’은 된소리로 발음함.)
		#
		def rule_14 kc, next_kc
			return if kc.jongsung.nil? || kc.jongsung == 'ㅇ' || next_kc.nil? || next_kc.chosung != 'ㅇ'
			if consonants = double_consonant_map[kc.jongsung]
				consonants[1] = 'ㅆ' if consonants[1] == 'ㅅ'
				kc.jongsung, next_kc.chosung = consonants

				true
			end
		end
		# 제15항: 받침 뒤에 모음 ‘ㅏ, ㅓ, ㅗ, ㅜ, ㅟ’들로 시작되는 __실질 형태소__가 연결되는
		# 경우에는, 대표음으로 바꾸어서 뒤 음절 첫소리로 옮겨 발음한다.
		def rule_15 kc, next_kc
			return if kc.jongsung.nil? || kc.jongsung == 'ㅇ' || next_kc.nil? || next_kc.chosung != 'ㅇ'

			if false && %w[ㅏ ㅓ ㅗ ㅜ ㅟ].include?(next_kc.jungsung) &&
					%[ㅆ ㄲ ㅈ ㅊ ㄵ ㄻ ㄾ ㄿ ㄺ].include?(kc.jongsung) == false # PATCH
				next_kc.chosung = @pconfig['jongsung sound'][ kc.jongsung ]
				kc.jongsung = nil

				true
			end
		end

		# 제16항: 한글 자모의 이름은 그 받침소리를 연음하되, ‘ㄷ, ㅈ, ㅊ, ㅋ, ㅌ,
		# ㅍ, ㅎ’의 경우에는 특별히 다음과 같이 발음한다.
		def rule_16 kc, next_kc
			return if next_kc.nil?

			map = {'디귿' => '디긋',
				   '지읒' => '지읏',
				   '치읓' => '치읏',
				   '키읔' => '키윽',
				   '티읕' => '티읏',
				   '피읖' => '피읍',
				   '히읗' => '히읏'}

			word = kc.to_s + next_kc.to_s
			if map.keys.include? word
				new_char = @korean.dissect(map[word][1])[0]
				next_kc.chosung = new_char.chosung
				next_kc.jongsung = new_char.jongsung

				true
			end
		end

		# 제17항: 받침 ‘ㄷ, ㅌ(ㄾ)’이 조사나 접미사의 모음 ‘ㅣ’와 결합되는 경우에는,
		# [ㅈ, ㅊ]으로 바꾸어서 뒤 음절 첫소리로 옮겨 발음한다.
		#
		# [붙임] ‘ㄷ’ 뒤에 접미사 ‘히’가 결합되어 ‘티’를 이루는 것은 [치]로 발음한다.
		def rule_17 kc, next_kc
			return if next_kc.nil? || %w[ㄷ ㅌ ㄾ].include?(kc.jongsung) == false

			if next_kc.to_s == '이'
				next_kc.chosung = kc.jongsung == 'ㄷ' ? 'ㅈ' : 'ㅊ'
				kc.jongsung = (dc = double_consonant_map[kc.jongsung]) && dc.first

				true
			elsif next_kc.to_s == '히'
				next_kc.chosung = 'ㅊ'
				kc.jongsung = (dc = double_consonant_map[kc.jongsung]) && dc.first

				true
			end
		end

		# 제18항: 받침 ‘ㄱ(ㄲ, ㅋ, ㄳ, ㄺ), ㄷ(ㅅ, ㅆ, ㅈ, ㅊ, ㅌ, ㅎ), ㅂ(ㅍ, ㄼ,
		# ㄿ, ㅄ)’은 ‘ㄴ, ㅁ’ 앞에서 [ㅇ, ㄴ, ㅁ]으로 발음한다.
		def rule_18 kc, next_kc
			map = {
				%w[ㄱ ㄲ ㅋ ㄳ ㄺ] => 'ㅇ', 
				%w[ㄷ ㅅ ㅆ ㅈ ㅊ ㅌ ㅎ] => 'ㄴ', 
				%w[ㅂ ㅍ ㄼ ㄿ ㅄ] => 'ㅁ'
			}
			if next_kc && map.keys.flatten.include?(kc.jongsung) && %w[ㄴ ㅁ].include?(next_kc.chosung)
				kc.jongsung = map[ map.keys.find { |e| e.include? kc.jongsung } ]

				true
			end
		end

		# 제19항: 받침 ‘ㅁ, ㅇ’ 뒤에 연결되는 ‘ㄹ’은 [ㄴ]으로 발음한다.
		# [붙임]받침 ‘ㄱ, ㅂ’ 뒤에 연결되는 ‘ㄹ’도 [ㄴ]으로 발음한다.
		def rule_19 kc, next_kc
			if next_kc && next_kc.chosung == 'ㄹ' && %w[ㅁ ㅇ ㄱ ㅂ].include?(kc.jongsung)
				next_kc.chosung = 'ㄴ'

				case kc.jongsung
				when 'ㄱ' then kc.jongsung = 'ㅇ'
				when 'ㅂ' then kc.jongsung = 'ㅁ'
				end

				true
			end
		end

		# 제20항: ‘ㄴ’은 ‘ㄹ’의 앞이나 뒤에서 [ㄹ]로 발음한다.
		def rule_20 kc, next_kc
			return if next_kc.nil?

			to = if %w[견란 진란 산량 단력 권력 원령 견례
						단로 원론 원료 근류].include?(kc.org.to_s + next_kc.org.to_s)
					 'ㄴ'
				 else
					 'ㄹ'
				 end

			if kc.jongsung == 'ㄹ' && next_kc.chosung == 'ㄴ'
				kc.jongsung = next_kc.chosung = to

				true
			elsif kc.jongsung == 'ㄴ' && next_kc.chosung == 'ㄹ'
				kc.jongsung = next_kc.chosung = to

				true
			end
		end

		# 제23항: 받침 ‘ㄱ(ㄲ, ㅋ, ㄳ, ㄺ), ㄷ(ㅅ, ㅆ, ㅈ, ㅊ, ㅌ), ㅂ(ㅍ, ㄼ, ㄿ,ㅄ)’
		# 뒤에 연결되는 ‘ㄱ, ㄷ, ㅂ, ㅅ, ㅈ’은 된소리로 발음한다.
		def rule_23 kc, next_kc
			return if next_kc.nil?
			if fortis_map.keys.include?(next_kc.chosung) &&
				%w[ㄱ ㄲ ㅋ ㄳ ㄺ ㄷ ㅅ ㅆ ㅈ ㅊ ㅌ ㅂ ㅍ ㄼ ㄿ ㅄ].include?(kc.jongsung)
				next_kc.chosung = fortis_map[next_kc.chosung]

				true
			end
		end

		# 제24항: 어간 받침 ‘ㄴ(ㄵ), ㅁ(ㄻ)’ 뒤에 결합되는 어미의 첫소리 ‘ㄱ, ㄷ, ㅅ, ㅈ’은 된소리로 발음한다.
		# 다만, 피동, 사동의 접미사 ‘-기-’는 된소리로 발음하지 않는다.
		# 용언 어간에만 적용.
		def rule_24 kc, next_kc
			return if next_kc.nil? || 
				next_kc.to_s == '기' # FIXME 피동/사동 여부 판단 불가. e.g. 줄넘기

			# FIXME 용언 여부를 판단. 정확한 판단 불가.
			return unless case kc.jongsung
			when 'ㄵ'
				%w[앉 얹].include? kc.to_s
			when 'ㄻ'
				%w[젊 닮].include? kc.to_s
			else
				false # XXX 일반적인 경우 사전 없이 판단 불가
			end

			if %w[ㄱ ㄷ ㅅ ㅈ].include?(next_kc.chosung) &&
				%w[ㄴ ㄵ ㅁ ㄻ ㄼ ㄾ].include?(kc.jongsung)
				next_kc.chosung = fortis_map[next_kc.chosung]

				true
			end
		end

		# 제25항: 어간 받침 ‘ㄼ, ㄾ’ 뒤에 결합되는 어미의 첫소리 ‘ㄱ, ㄷ, ㅅ, ㅈ’은
		# 된소리로 발음한다.
		def rule_25 kc, next_kc
			return if next_kc.nil?

			if %w[ㄱ ㄷ ㅅ ㅈ].include?(next_kc.chosung) &&
				%w[ㄼ ㄾ].include?(kc.jongsung)
				next_kc.chosung = fortis_map[next_kc.chosung]

				true
			end
		end

		# 제26항: 한자어에서, ‘ㄹ’ 받침 뒤에 연결되는 ‘ㄷ, ㅅ, ㅈ’은 된소리로 발음한다.
		def rule_26 kc, next_kc
			# TODO
		end

		# 제27항: __관형사형__ ‘-(으)ㄹ’ 뒤에 연결되는 ‘ㄱ, ㄷ, ㅂ, ㅅ, ㅈ’은 된소리로 발음한다.
		# - ‘-(으)ㄹ’로 시작되는 어미의 경우에도 이에 준한다.
		def rule_27 kc, next_kc
			# TODO
			
			return if next_kc.nil? || next_kc.to_s == '다' # PATCH

			if kc.jongsung == 'ㄹ' && %w[ㄱ ㄷ ㅂ ㅅ ㅈ].include?(next_kc.chosung)
				next_kc.chosung = fortis_map[next_kc.chosung]
				true
			end
		end

		# 제26항: 한자어에서, ‘ㄹ’ 받침 뒤에 연결되는 ‘ㄷ, ㅅ, ㅈ’은 된소리로 발음한다.
		# 제28항: 표기상으로는 사이시옷이 없더라도, 관형격 기능을 지니는 사이시옷이
		# 있어야 할(휴지가 성립되는) 합성어의 경우에는, 뒤 단어의 첫소리 ‘ㄱ, ㄷ,
		# ㅂ, ㅅ, ㅈ’을 된소리로 발음한다.
		def rule_26_28 kc, next_kc
			# TODO
		end

		# 제29항: 합성어 및 파생어에서, 앞 단어나 접두사의 끝이 자음이고 뒤 단어나
		# 접미사의 첫음절이 ‘이, 야, 여, 요, 유’인 경우에는, ‘ㄴ’ 음을 첨가하여
		# [니, 냐, 녀, 뇨, 뉴]로 발음한다.
		def rule_29 kc, next_kc
			# TODO
		end

		# 제30항: 사이시옷이 붙은 단어는 다음과 같이 발음한다.
		# 1. ‘ㄱ, ㄷ, ㅂ, ㅅ, ㅈ’으로 시작하는 단어 앞에 사이시옷이 올 때는 이들
		# 자음만을 된소리로 발음하는 것을 원칙으로 하되, 사이시옷을 [ㄷ]으로
		# 발음하는 것도 허용한다.
		# 2. 사이시옷 뒤에 ‘ㄴ, ㅁ’이 결합되는 경우에는 [ㄴ]으로 발음한다. 
		# 3. 사이시옷 뒤에 ‘이’ 음이 결합되는 경우에는 [ㄴㄴ]으로 발음한다.
		def rule_30 kc, next_kc
			return if next_kc.nil? || kc.jongsung != 'ㅅ'

			if %w[ㄱ ㄷ ㅂ ㅅ ㅈ].include? next_kc.chosung
				kc.jongsung = 'ㄷ' # or nil
				next_kc.chosung = fortis_map[next_kc.chosung]

				true
			elsif %w[ㄴ ㅁ].include? next_kc.chosung
				kc.jongsung = 'ㄴ'

				true
			elsif next_kc.chosung == 'ㅇ' &&
						%w[ㅣ ㅒ ㅖ ㅑ ㅕ ㅛ ㅠ].include?(next_kc.jungsung) &&
						next_kc.jongsung # PATCH
				kc.jongsung = next_kc.chosung = 'ㄴ'

				true
			end
		end
	end#Pronouncer
end#Korean
end#Gimchi
