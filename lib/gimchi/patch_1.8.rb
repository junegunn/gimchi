if RUBY_VERSION =~ /^1\.8\./
  $KCODE = 'U'

  class Gimchi
  private
    def str_length str
      str.scan(/./mu).length
    end
  end#Gimchi
end
