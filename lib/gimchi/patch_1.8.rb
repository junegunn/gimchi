$KCODE = 'U'

module Gimchi
class Korean
  # Checks if the given character is a korean character.
  # @param [String] ch A string of size 1
  def korean_char? ch
    raise ArgumentError.new('Lengthy input') if str_length(ch) > 1

    complete_korean_char?(ch) || 
      (chosungs + jungsungs + jongsungs).include?(ch)
  end

  # Checks if the given character is a "complete" korean character.
  # "Complete" Korean character must have chosung and jungsung, with optional jongsung.
  # @param [String] ch A string of size 1
  def complete_korean_char? ch
    raise ArgumentError.new('Lengthy input') if str_length(ch) > 1

    # Range of Korean chracters in Unicode 2.0: AC00(가) ~ D7A3(힣)
    ch.unpack('U').all? { | c | c >= 0xAC00 && c <= 0xD7A3 }
  end

private
  def str_length str
    str.scan(/./mu).length
  end
end#Korean
end#Gimchi
