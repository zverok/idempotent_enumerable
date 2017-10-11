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

  DEFAULT_METHOD_LIST = %i[
    reject
    select
    sort
    sort_by
  ].freeze

  DEFAULT_METHOD_LIST.each do |method|
    define_method(method) { |*arg, &block| idempotently_construct(each(*arg).send(method, &block)) }
  end

  private

  def idempotently_construct(array)
    self.class.send(self.class.idempotent_enumerable.constructor, array)
  end
end
