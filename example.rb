require_relative 'patternie'

class Filme
  fields :diretor,:ano, :premio
  def initialize(diretor, ano, premio) 
    @diretor=diretor
    @ano = ano
    @premio = premio
  end
end


pulpFiction = Filme.new( "Tarantino", 1994, Some.new("Palma de Ouro"))

_Filme[:nomeDoDiretor, 1994, :_] =~ pulpFiction
puts nomeDoDiretor == "Tarantino"

begin
  Filme[:nomeDoDiretor, 1995, :_] =~ pulpFiction
  raise "Should have not mached"
rescue
  # ok
end

mequetrefe = Filme.new("Joao Mequetrefe", 2012, None.new)

# if you dont want to mess up with object that bad, use this version
g = Filme[:diretor, :_, None] =~ mequetrefe
puts g.diretor=="Joao Mequetrefe"

# example with recursive matching
_Filme[:diretor, :_, Some[:premio]] =~ pulpFiction
puts premio=="Palma de Ouro"

def descreveDiretor(filme)
  filme.match do
    caso Filme[:diretor, :_, Some[:premio]] do
      puts "#{diretor} won #{premio}"
    end
    caso Filme[:diretor, :_, None] do
      puts "#{diretor} nao ganhou nada"
    end
  end
end

descreveDiretor pulpFiction
descreveDiretor mequetrefe


# todo refactor code to use custom unapply instead of Matcher, default unapply uses Matcher
