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

  SIMPLE_METHOD_LIST = %i[
    drop_while
    reject
    select
    sort
    sort_by
    take_while
    uniq
  ].freeze

  SIMPLE_METHOD_LIST.each do |method|
    define_method(method) { |*arg, &block| idempotently_construct(each(*arg).send(method, &block)) }
  end

  def drop(num, *arg)
    idempotently_construct(each(*arg).drop(num))
  end

  def first(num = nil)
    return super() unless num
    idempotently_construct(each.first(num))
  end

  def min(num = nil)
    return super unless num
    idempotently_construct(each.min(num))
  end

  def min_by(num = nil, &block)
    return super unless num
    idempotently_construct(each.min_by(num, &block))
  end

  def max(num = nil)
    return super unless num
    idempotently_construct(each.max(num))
  end

  def max_by(num = nil, &block)
    return super unless num
    idempotently_construct(each.max_by(num, &block))
  end

  def grep(pattern, *arg, &block)
    idempotently_construct(each(*arg).grep(pattern, &block))
  end

  def grep_v(pattern, *arg, &block)
    idempotently_construct(each(*arg).grep_v(pattern, &block))
  end

  def take(num, *arg)
    idempotently_construct(each(*arg).take(num))
  end

  private

  def idempotently_construct(array)
    self.class.send(self.class.idempotent_enumerable.constructor, array)
  end
end
