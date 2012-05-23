require 'hashie' # TODO use a simpler version instead of hashie

module Patternie
  def fields(*fields)
    @pattern = fields
    fields.each do |f|
      self.send :attr_accessor, f
    end
  end
  def [](*args) # todo: change to ()
    PatternieMatcher.new(args, @pattern, self)
  end
end

class MatchBlock
  def initialize(to_match)
    @to_match = to_match
  end
  def caso(matcher, &block)
    begin
      extra = matcher =~ @to_match
      extra.instance_eval(&block)
    rescue
      # todo should only ignore MatchError
    end
  end
end

class Object
  include Patternie
  def match(&lambda)
    MatchBlock.new(self).instance_eval(&lambda)
  end
end

class Option
  
end
class Some < Option
  fields :value
  def initialize(value)
    @value = value
  end
  def is_defined?
    true
  end
  def get
    @value
  end
end
class None < Option
  def is_defined?
    false
  end
  def get
    raise "None has no value"
  end
end

class PatternieMatcher
  def initialize(left, pattern, type)
    if left.size != pattern.size
      raise "Cannot match due to partial matching (#{left} #{pattern})" 
    end
    @left = left
    @pattern = pattern
    @type = type
  end
  
  def =~(right)
    if !right.kind_of? @type
      raise "Cannot match a #{right} because it is not a #{@type}" 
    end
    
    object = Hashie::Mash.new
    (0..@pattern.size-1).each do |i|
      field = "@#{@pattern[i].to_s}".to_sym
      to_match = @left[i]
      apply_to(to_match, object, right, field)
    end
    # puts "returning #{object}"
    object
  end
  
  private
  def apply_to(to_match, object, right, field)
    return if to_match == :_
    
    value = right.instance_variable_get field
    
    if to_match.kind_of? Symbol
      object[to_match] = value
    elsif to_match.kind_of? Class
      if !value.kind_of?(to_match)
        raise "Cannot match #{value} to class type #{to_match}"
      end
    elsif to_match.kind_of?(PatternieMatcher)
      extra = to_match =~ value
      object.merge! extra
    else
      if value != to_match
        raise "Cannot match #{value} to #{to_match}"
      end
    end
  end
end

class Object
  def method_missing(name)
    if(name.to_s[0]=='_')
      type = eval(name.to_s[1..name.size-1])
      MatcherWrapper.new(type, self)
    else
      super
    end
  end
end

# only required for 'simple matching'
class MatcherWrapper
  def initialize(t, scope)
    @type = t
    @scope = scope
  end
  def [](*args)
    @matcher = @type[*args]
    self
  end
  def =~(value)
    extra = @matcher =~ value
    extra.each do |k, v|
      @scope.define_singleton_method k.to_sym do
        v # TODO something cuter, please
      end
    end
  end
end
