$KCODE = 'U'

module Gimchi
class Korean
private
  def str_length str
    str.scan(/./mu).length
  end
end#Korean
end#Gimchi
