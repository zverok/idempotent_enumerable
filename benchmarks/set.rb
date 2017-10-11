require 'bundler/setup'
require 'idempotent_enumerable'
require 'set'
require 'benchmark/ips'

set1 = Set.new((1..100))
class SetI < Set
  include IdempotentEnumerable
end
set2 = SetI.new((1..100))

Benchmark.ips do |x|
  x.report('Enumerable') { set1.reject(&:odd?) }
  x.report('IdempotentEnumerable') { set2.reject(&:odd?) }

  x.compare!
end

