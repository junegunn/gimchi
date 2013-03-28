# gimchi

## 개요

Gimchi는 한글 스트링을 다롭니다.
국립 국어원 어문 규정에 정의된 한글의 표준 발음법과
로마자 표기법을 (일부) 구현한 것이 주요 기능입니다.

또한 다음의 기능들을 제공합니다.
- 주어진 캐릭터가 한글인지 판단
- 한글을 초성, 중성, 종성으로 분리하고, 이를 다시 합치는 기능
- 숫자 표기를 한글 표현으로 변환

## 설치
```
gem install gimchi
```

## 사용법

### 초/중/종성 분해/합체

```ruby
chosung, jungsung, jongsung = Gimchi.decompose "한"

Gimchi.compose chosung, jungsung, jongsung    # 한
Gimchi.compose chosung, "ㅗ", jongsung        # 혼
```

### 한글 캐릭터 여부 판단
```ruby
Gimchi.korean_char? 'ㄱ'           # true
Gimchi.complete_korean_char? 'ㄱ'  # false

Gimchi.korean_char? 'ㅏ'           # true
Gimchi.complete_korean_char? 'ㅏ'  # false

Gimchi.korean_char? '가'           # true
Gimchi.complete_korean_char? '가'  # true

# Alias of korean_char?
Gimchi.kchar? '가'                 # true

Gimchi.chosung?  'ㄱ'              # true
Gimchi.jungsung? 'ㄱ'              # false
Gimchi.jongsung? 'ㄱ'              # true

Gimchi.chosung?  'ㅏ'              # false
Gimchi.jungsung? 'ㅏ'              # true
Gimchi.jongsung? 'ㅏ'              # false

Gimchi.chosung?  'ㄺ'              # false
Gimchi.jungsung? 'ㄺ'              # false
Gimchi.jongsung? 'ㄺ'              # true
```

### Gimchi::Char 의 사용

```ruby
kc = Gimchi::Char("한")
kc.class                    # Gimchi::Char

kc.chosung                  # "ㅎ"
kc.jungsung                 # "ㅏ"
kc.jongsung                 # "ㄴ"
kc.to_a                     # ["ㅎ", "ㅏ", "ㄴ"]
kc.to_s                     # "한"

kc.complete?                # true
kc.partial?                 # false

Gimchi::Char("ㅏ").partial? # true

# Modifying its elements
kc.chosung = 'ㄷ'
kc.jongsung = 'ㄹ'
kc.to_s                     # "달"
kc.complete?                # true
kc.partial?                 # false

kc.chosung = nil
kc.jongsung = nil
kc.complete?                # false
kc.partial?                 # true
```

### 숫자 읽기
```ruby
Gimchi.read_number(1999)         # "천 구백 구십 구"
Gimchi.read_number(- 100.123)    # "마이너스 백점일이삼"
Gimchi.read_number("153,191,100,678.3214")
    # "천 오백 삼십 일억 구천 백 십만 육백 칠십 팔점삼이일사"

# 나이, 시간 ( -살, -시 )
Gimchi.read_number("20살")       # "스무살"
Gimchi.read_number("13 살")      # "열세 살"
Gimchi.read_number("7시 30분")   # "일곱시 삼십분"
```

### 표준 발음 (부분 구현)
```ruby
str = "됐어 됐어 이제 그런 가르침은 됐어 매일 아침 7 시 30 분까지 우릴 조그만 교실로 몰아넣고"
Gimchi.pronounce str
  # "돼써 돼써 이제 그런 가르치믄 돼써 매일 아침 일곱 시 삼십 분까지 우릴 조그만 교실로 모라너코"

Gimchi.pronounce str, :slur => true
  # "돼써 돼써 이제 그런 가르치믄 돼써 매이 라치 밀곱 씨 삼십 뿐까지 우릴 조그만 교실로 모라너코"

Gimchi.pronounce str, :each_char => true
  # "됃어 됃어 이제 그런 가르침은 됃어 매일 아침 일곱 시 삼십 분까지 우릴 조그만 교실로 몰아너고"

Gimchi.pronounce str, :number => false
  # "돼써 돼써 이제 그런 가르치믄 돼써 매일 아침 7 시 30 분까지 우릴 조그만 교실로 모라너코"
```

### 로마자 표기 (부분 구현)
```ruby
str = "됐어 됐어 이제 그런 가르침은 됐어 매일 아침 7 시 30 분까지 우릴 조그만 교실로 몰아넣고"

Gimchi.romanize str
  # "Dwaesseo dwaesseo ije geureon gareuchimeun dwaesseo mae-il achim ilgop si samsip bunkkaji uril jogeuman gyosillo moraneoko"

Gimchi.romanize str, :slur => true
  # "Dwaesseo dwaesseo ije geureon gareuchimeun dwaesseo mae-i rachi milgop ssi samsip ppunkkaji uril jogeuman gyosillo moraneoko"

Gimchi.romanize str, :number => false
  # "Dwaesseo dwaesseo ije geureon gareuchimeun dwaesseo mae-il achim 7 si 30 bunkkaji uril jogeuman gyosillo moraneoko"

Gimchi.romanize str, :as_pronounced => false
  # "Dwaet-eo dwaet-eo ije geureon gareuchim-eun dwaet-eo mae-il achim ilgop si samsip bunkkaji uril jogeuman gyosillo mol-aneogo"
```

## 구현의 한계

표준 발음법과 로마어 표기법을 모두 구현하기 위해서는 형태소 분석과 충분한
사전, 그리고 문맥의 의미 분석이 필요합니다. 이 모든 것이 준비된다고 할 지라도
완벽한 결과를 얻는 것은 불가능합니다.
이는 현재 gimchi가 목표로 하는 것이 아니며 gimchi는 간단한 구현으로 어느 수준
이상의 결과를 얻는 것을 목표로 합니다. 현재 구현의 한계 내에서 정확도를 올리기
위해 Ad-hoc한 patch 등이 코드에 상당량 포함된 상태인데 이를 정제하고 체계화하는
노력이 필요합니다.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2013 Junegunn Choi. See LICENSE.txt for
further details.

