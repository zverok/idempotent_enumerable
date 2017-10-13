module IdempotentEnumerable
  class Configurator
    attr_writer :constructor

    def initialize(host)
      @host = host
    end

    def constructor
      @constructor || :new
    end

    def redefine_map!(only: %i[map flat_map], all: nil)
      only = Array(only)
      redefine(:map, all) if only.include?(:map)
      redefine(:flat_map, all) if only.include?(:flat_map)
      self
    end

    private

    def redefine(method, all)
      @host.send(:define_method, method) do |*arg, &block|
        res = each(*arg).send(method, &block)
        if !all || res.all?(&all)
          idempotently_construct(res)
        else
          res
        end
      end
    end
  end
end
