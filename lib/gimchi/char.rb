# encoding: UTF-8

class Gimchi
  # Class representing each Korean character. Its three components,
  # `chosung', `jungsung' and `jongsung' can be get and set.
  #
  # `to_s' merges components into a String. `to_a' returns the three components.
  class Char
    # @return [String] Chosung component of this character.
    attr_reader :chosung
    # @return [String] Jungsung component of this character.
    attr_reader :jungsung
    # @return [String] Jongsung component of this character.
    attr_reader :jongsung

    # @param [String] kchar Korean character string
    def initialize kchar
      raise ArgumentError.new('Not a korean character') unless Gimchi.korean_char? kchar

      if Gimchi.complete_korean_char? kchar
        c = kchar.unpack('U').first
        n = c - 0xAC00
        # '가' ~ '깋' -> 'ㄱ'
        n1 = n / (21 * 28)
        # '가' ~ '깋'에서의 순서
        n = n % (21 * 28)
        n2 = n / 28;
        n3 = n % 28;
        self.chosung = Gimchi.chosungs[n1]
        self.jungsung = Gimchi.jungsungs[n2]
        self.jongsung = ([nil] + Gimchi.jongsungs)[n3]
      elsif Gimchi.chosung? kchar
        self.chosung = kchar
      elsif Gimchi.jungsung? kchar
        self.jungsung = kchar
      elsif Gimchi.jongsung? kchar
        self.jongsung = kchar
      end
    end

    # Recombines components into a korean character.
    # @return [String] Combined korean character
    def to_s
      Gimchi.compose chosung, jungsung, jongsung
    end

    # Sets the chosung component.
    # @param [String]
    def chosung= c
      raise ArgumentError.new('Invalid chosung component') if
          c && Gimchi.chosung?(c) == false
      @chosung = c && c.dup.extend(Component).tap { |e| e.kor = Gimchi }
    end

    # Sets the jungsung component
    # @param [String]
    def jungsung= c
      raise ArgumentError.new('Invalid jungsung component') if
          c && Gimchi.jungsung?(c) == false
      @jungsung = c && c.dup.extend(Component).tap { |e| e.kor = Gimchi }
    end

    # Sets the jongsung component
    #
    # @param [String]
    def jongsung= c
      raise ArgumentError.new('Invalid jongsung component') if
          c && Gimchi.jongsung?(c) == false
      @jongsung = c && c.dup.extend(Component).tap { |e| e.kor = Gimchi }
    end

    # Returns Array of three components.
    #
    # @return [Array] Array of three components
    def to_a
      [chosung, jungsung, jongsung]
    end

    # Checks if this is a complete Korean character.
    def complete?
      chosung.nil? == false && jungsung.nil? == false
    end

    # Checks if this is a non-complete Korean character.
    # e.g. ㅇ, ㅏ
    def partial?
      chosung.nil? || jungsung.nil?
    end

    def inspect
      "#{to_s}(#{to_a.join('/')})"
    end

  private
    # Three components of Gimchi::Char are extended to support #vowel? and #consonant? method.
    module Component
      # @return [Korean] Hosting Korean instance
      attr_accessor :kor

      # Is this component a vowel?
      def vowel?
        kor.jungsung? self
      end

      # Is this component a consonant?
      def consonant?
        self != 'ㅇ' && kor.chosung?(self)
      end
    end#Component
  end#Char
end#Gimchi

