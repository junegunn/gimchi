# encoding: UTF-8

module Gimchi
class Korean
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

    # @param [Gimchi::Korean] kor Gimchi::Korean instance
    # @param [String] kchar Korean character string
    def initialize kor, kchar
      raise ArgumentError.new('Not a korean character') unless kor.korean_char? kchar

      @kor = kor
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
      elsif @kor.chosungs.include? kchar
        self.chosung = kchar
      elsif @kor.jungsungs.include? kchar
        self.jungsung = kchar
      elsif @kor.jongsungs.include? kchar
        self.jongsung = kchar
      end
    end

    # Recombines components into a korean character.
    # @return [String] Combined korean character
    def to_s
      if chosung.nil? && jungsung.nil?
        ""
      elsif chosung && jungsung
        n1, n2, n3 = 
        n1 = @kor.chosungs.index(chosung) || 0
        n2 = @kor.jungsungs.index(jungsung) || 0
        n3 = ([nil] + @kor.jongsungs).index(jongsung) || 0
        [ 0xAC00 + n1 * (21 * 28) + n2 * 28 + n3 ].pack('U')
      else
        chosung || jungsung
      end
    end

    # Sets the chosung component.
    # @param [String] 
    def chosung= c
      raise ArgumentError.new('Invalid chosung component') if
          c && @kor.chosungs.include?(c) == false
      @chosung = c && c.dup.extend(Component).tap { |e| e.kor = @kor }
    end

    # Sets the jungsung component
    # @param [String] 
    def jungsung= c
      raise ArgumentError.new('Invalid jungsung component') if
          c && @kor.jungsungs.include?(c) == false
      @jungsung = c && c.dup.extend(Component).tap { |e| e.kor = @kor }
    end

    # Sets the jongsung component
    #
    # @param [String] 
    def jongsung= c
      raise ArgumentError.new('Invalid jongsung component') if
          c && @kor.jongsungs.include?(c) == false
      @jongsung = c && c.dup.extend(Component).tap { |e| e.kor = @kor }
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
    # Three components of Korean::Char are extended to support #vowel? and #consonant? method.
    module Component
      # @return [Korean] Hosting Korean instance
      attr_accessor :kor

      # Is this component a vowel?
      def vowel?
        kor.jungsungs.include? self
      end

      # Is this component a consonant?
      def consonant?
        self != 'ㅇ' && kor.chosungs.include?(self)
      end
    end#Component
  end#Char
end#Korean
end#Gimchi

