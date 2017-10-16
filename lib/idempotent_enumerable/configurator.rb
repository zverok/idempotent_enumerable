module IdempotentEnumerable
  class Configurator
    attr_writer :constructor

    def initialize(host)
      @host = host
    end

    def constructor
      @constructor || :new
    end

    REDEFINEABLE = %i[map flat_map collect collect_concat].freeze

    def redefine_map!(only: REDEFINEABLE, all: nil)
      (Array(only) & REDEFINEABLE).each { |method| redefine(method, all) }
      self
    end

    private

    def redefine(method, all)
      @host.send(:define_method, method) do |*arg, &block|
        return to_enum(method) unless block
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
