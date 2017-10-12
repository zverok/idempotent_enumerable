module IdempotentEnumerable
  include Enumerable

  class Configurator
    attr_writer :constructor

    def constructor
      @constructor || :new
    end
  end

  def self.included(klass)
    def klass.idempotent_enumerable
      @idempotent_enumerable ||= Configurator.new
    end
  end

  SIMPLE_METHODS = %i[
    drop_while
    reject
    select
    sort_by
    take_while
    uniq
  ].freeze

  SIMPLE_METHODS.each do |method|
    define_method(method) { |*arg, &block|
      return to_enum(method, *arg) unless block
      idempotently_construct(each(*arg).send(method, &block))
    }
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

  def grep_v(pattern, *arg, &block)
    idempotently_construct(each(*arg).grep_v(pattern, &block))
  end

  def group_by(*arg, &block)
    each(*arg).group_by(&block).map { |key, val| [key, idempotently_construct(val)] }.to_h
  end

  def min(num = nil)
    return super unless num
    idempotently_construct(each.min(num))
  end

  def min_by(num = nil, &block)
    return super unless num
    return to_enum(:min_by) unless block
    idempotently_construct(each.min_by(num, &block))
  end

  def max(num = nil)
    return super unless num
    idempotently_construct(each.max(num))
  end

  def max_by(num = nil, &block)
    return super unless num
    return to_enum(:max_by) unless block
    idempotently_construct(each.max_by(num, &block))
  end

  def partition(*arg, &block)
    return to_enum(:partition, *arg) unless block
    each(*arg).partition(&block).map(&method(:idempotently_construct))
  end

  def sort(*arg, &block)
    idempotently_construct(each(*arg).sort(&block))
  end

  def take(num, *arg)
    idempotently_construct(each(*arg).take(num))
  end

  private

  def idempotently_construct(array)
    self.class.send(self.class.idempotent_enumerable.constructor, array)
  end
end
