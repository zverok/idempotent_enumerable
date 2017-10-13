module IdempotentEnumerable
  include Enumerable

  def self.included(klass)
    def klass.idempotent_enumerable
      @idempotent_enumerable ||= Configurator.new(self)
    end
  end

  %i[drop_while reject select sort_by take_while].each do |method|
    define_method(method) do |*arg, &block|
      return to_enum(method, *arg) unless block
      idempotently_construct(each(*arg).send(method, &block))
    end
  end

  def chunk(*arg, &block)
    # FIXME: should return enumerator
    return to_enum(:chunk, *arg) unless block
    each(*arg).chunk(&block).map { |key, group| [key, idempotently_construct(group)] }
  end

  if RUBY_VERSION >= '2.3.0'
    def chunk_while(*arg, &block)
      idempotent_enumerator(each(*arg).chunk_while(&block))
    end
  end

  def drop(num, *arg)
    idempotently_construct(each(*arg).drop(num))
  end

  def each_cons(num, *arg)
    return to_enum(:each_cons, num, *arg) unless block_given?
    each(*arg).each_cons(num) { |slice| yield(idempotently_construct(slice)) }
  end

  def each_slice(num, *arg)
    return to_enum(:each_slice, num, *arg) unless block_given?
    each(*arg).each_slice(num) { |slice| yield(idempotently_construct(slice)) }
  end

  def first(num = nil)
    return super() unless num
    idempotently_construct(each.first(num))
  end

  def grep(pattern, *arg, &block)
    idempotently_construct(each(*arg).grep(pattern, &block))
  end

  if RUBY_VERSION >= '2.3.0'
    def grep_v(pattern, *arg, &block)
      idempotently_construct(each(*arg).grep_v(pattern, &block))
    end
  end

  def group_by(*arg, &block)
    each(*arg).group_by(&block).map { |key, val| [key, idempotently_construct(val)] }.to_h
  end

  def min(num = nil)
    return super() unless num
    idempotently_construct(each.min(num))
  end

  def min_by(num = nil, &block)
    return super(&block) unless num
    return to_enum(:min_by) unless block
    idempotently_construct(each.min_by(num, &block))
  end

  def max(num = nil)
    return super() unless num
    idempotently_construct(each.max(num))
  end

  def max_by(num = nil, &block)
    return super(&block) unless num
    return to_enum(:max_by) unless block
    idempotently_construct(each.max_by(num, &block))
  end

  def partition(*arg, &block)
    return to_enum(:partition, *arg) unless block
    each(*arg).partition(&block).map(&method(:idempotently_construct))
  end

  def slice_before(pattern = nil, &block)
    idempotent_enumerator(pattern ? each.slice_before(pattern) : each.slice_before(&block))
  end

  if RUBY_VERSION >= '2.2'
    def slice_after(pattern = nil, &block)
      idempotent_enumerator(pattern ? each.slice_after(pattern) : each.slice_after(&block))
    end

    def slice_when(*arg, &block)
      idempotent_enumerator(each(*arg).slice_when(&block))
    end
  end

  def sort(*arg, &block)
    idempotently_construct(each(*arg).sort(&block))
  end

  def take(num, *arg)
    idempotently_construct(each(*arg).take(num))
  end

  if RUBY_VERSION >= '2.4.0'
    def uniq(*arg, &block)
      idempotently_construct(each(*arg).uniq(&block))
    end
  end

  private

  def idempotently_construct(array)
    self.class.send(self.class.idempotent_enumerable.constructor, array)
  end

  def idempotent_enumerator(enumerator)
    Enumerator.new { |y| enumerator.each { |chunk| y << idempotently_construct(chunk) } }
  end
end

require_relative 'idempotent_enumerable/configurator'
