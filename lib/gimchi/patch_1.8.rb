if RUBY_VERSION =~ /^1\.8\./
  $KCODE = 'U'

  class Gimchi
    class << self
    private
    def str_length str
      str.scan(/./mu).length
    end
    end
  end#Gimchi
end
