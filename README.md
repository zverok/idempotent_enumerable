**IdempotentEnumerable** is like Ruby's core `Enumerable` but tries to preserve the class of the
collection it included in, where reasonable.

## Features/Showcase

```ruby
require 'set'

s = Set.new(1..5)
# => #<Set: {1, 2, 3, 4, 5}>
s.reject(&:odd?)
# => [2, 4] -- FFFUUUU

require 'idempotent_enumerable'

class Set
  include IdempotentEnumerable
end

s.reject(&:odd?)
# => #<Set: {2, 4}> -- Nice!
```

To construct back an instance of original class, `IdempotentEnumerable` relies on the fact
`OriginalClass.new(array)` call will work. But, if your class provides another way for construction
from array, you can still use the module:

```ruby
h = {a: 1, b: 2, c: 3}
# => {:a=>1, :b=>2, :c=>3}
h.first(2)
# => [[:a, 1], [:b, 2]]

# To make hash from this array, one should use `Hash[array]` notation.

class Hash
  include IdempotentEnumerable
  idempotent_enumerable.constructor = :[]
end

h.first(2)
# => {:a=>1, :b=>2}
```

`IdempotentEnumerable` also supports complicated collections, with `each` accepting additional
arguments ([daru](https://github.com/SciRuby/daru) used as an example):

```ruby
require 'daru'

Daru::DataFrame.include IdempotentEnumerable

df = Daru::DataFrame.new([[1,2,3], [4,5,6], [7,8,9]])
# #<Daru::DataFrame(3x3)>
#        0   1   2
#    0   1   4   7
#    1   2   5   8
#    2   3   6   9

# :column argument would be passed to DataFrame#each, so we are selecting columns
df.select(:column) { |col| col.sum > 6 }
# #<Daru::DataFrame(3x2)>
#        0   1
#    0   4   7
#    1   5   8
#    2   6   9
```

## List of methods redefined


* `uniq` (RUBY_VERSION >= 2.4).

## Performance penalty

...is, of course, present, but not that awful (depends on your standards).

```ruby
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
```

Output:
```
Warming up --------------------------------------
          Enumerable    10.681k i/100ms
IdempotentEnumerable     4.035k i/100ms
Calculating -------------------------------------
          Enumerable    112.134k (± 3.5%) i/s -    566.093k in   5.055148s
IdempotentEnumerable     42.197k (± 4.1%) i/s -    213.855k in   5.078339s

Comparison:
          Enumerable:   112134.2 i/s
IdempotentEnumerable:    42196.6 i/s - 2.66x  slower
```
