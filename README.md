# IdempotentEnumerable

[![Gem Version](https://badge.fury.io/rb/idempotent_enumerable.svg)](http://badge.fury.io/rb/idempotent_enumerable)
[![Build Status](https://travis-ci.org/zverok/idempotent_enumerable.svg?branch=master)](https://travis-ci.org/zverok/idempotent_enumerable)
[![Coverage Status](https://coveralls.io/repos/zverok/idempotent_enumerable/badge.svg?branch=master)](https://coveralls.io/r/zverok/idempotent_enumerable?branch=master)


`IdempotentEnumerable` is like Ruby core's `Enumerable` but tries to preserve the class of the
collection it included in, where reasonable.

## Features/Showcase

```ruby
require 'set'

s = Set.new(1..5)
# => #<Set: {1, 2, 3, 4, 5}>
s.reject(&:odd?)
# => [2, 4] -- FFFUUUU

require 'idempotent_enumerable'
Set.include IdempotentEnumerable

s.reject(&:odd?)
# => #<Set: {2, 4}> -- Nice!
```

`IdempotentEnumerable` relies on fact your `each` method returns an instance of `Enumerator` (or
other `Enumerable` object) when called without block. Which, honestly, it should do anyways.

To construct back an instance of original class, `IdempotentEnumerable` relies on the fact
`OriginalClass.new(array)` call will work. But, if your class provides another way for construction
from array, you can still use the module:

```ruby
h = {a: 1, b: 2, c: 3}
# => {:a=>1, :b=>2, :c=>3}
h.first(2)
# => [[:a, 1], [:b, 2]]

Hash.include IdempotentEnumerable

# To make hash from array of pairs, one should use `Hash[array]` notation.
Hash.idempotent_enumerable.constructor = :[]

h.first(2)
# => {:a=>1, :b=>2}
```

`IdempotentEnumerable` also supports complicated collections, with `each` accepting additional
arguments, out of the box ([daru](https://github.com/SciRuby/daru) used as an example):

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

## Reasons

`IdempotentEnumerable` can be used as:

* soft patch to existing Ruby collections (like `Set` or `Hash`);
* custom reimplementations of generic collections (some `FasterArray`);
* custom specialized collection, like [Nokogiri::XML::NodeSet](http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/NodeSet),
  which quacks like `Array`, but also provides XML/CSS navigation methods. Unfortunately, if you'll
  do something like `doc.search('a').reject { |a| a.text.include?('Google') }`, you'll receive regular
  `Array` that haven't any useful `#at`/`#search` methods anymore.

## Installation and usage

`gem install idempotent_enumerable` or `gem 'idempotent_enumerable'` in your `Gemfile`.

Then follow examples in this README.

## List of methods redefined

### Methods that return single collection

* [drop](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-drop);
* [drop_while](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-drop_while);
* [first](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-first) (when used with argument);
* [grep](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-grep);
* [grep_v](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-grep_v) (RUBY_VERSION >= 2.3);
* [max](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-max) (when used with argument, RUBY_VERSION >= 2.2);
* [max_by](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-max_by) (when used with argument, RUBY_VERSION >= 2.2);
* [min](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-min) (when used with argument, RUBY_VERSION >= 2.2);
* [min_by](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-min_by) (when used with argument, RUBY_VERSION >= 2.2);
* [reduce](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-reduce);
* [reject](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-reject);
* [select](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-select);
* [sort](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-sort);
* [sort_by](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-sort_by);
* [take](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-take);
* [take_while](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-take_while);
* [uniq](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-uniq)  (RUBY_VERSION >= 2.4).

### Methods that return (or emit) several collections

For methods like [partition](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-partition) that
somehow split an enumerable sequence into several, `IdempotentEnumerable` preserves the type of
**internal** sequence. E.g.:

```ruby
Set.include IdempotentEnumerable
set = Set.new(1..5)
set.partition(&:odd?)
# => [#<Set: {1, 3, 5}>, #<Set: {2, 4}>]
set.each_slice(3).to_a
# => [#<Set: {1, 2, 3}>, #<Set: {4, 5}>]
```

* [chunk](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-chunk);
* [chunk_while](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-chunk_while) (RUBY_VERSION >= 2.3);
* [each_cons](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-each_cons);
* [each_slice](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-each_slice);
* [group_by](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-group_by) (returns hash with
  keys being group keys and values being original collection type);
* [partition](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-partition);
* [slice_after](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-slice_after) (RUBY_VERSION >= 2.2);
* [slice_before](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-slice_before);
* [slice_when](https://ruby-doc.org/core-2.4.2/Enumerable.html#method-i-slice_when) (RUBY_VERSION >= 2.2).

### Optionally redefined methods

Generally speaking, `map` and `flat_map` can return collection of anything, probably not coercible
to original collection type, so they are **not** redefined by default.

But they can be redefined with optional `idempotent_enumerable.redefine_map!` call:

```ruby
Set.include IdempotentEnumerable
set = Set.new(1..5)
set.map(&:to_s)
# => ["1", "2", "3", "4", "5"]
Set.idempotent_enumerable.redefine_map!
set.map(&:to_s)
# => #<Set: {"1", "2", "3", "4", "5"}>
```

`redefine_map!` has two options:
* `only:` (by default `[:map, :flat_map]`) to specify that you want to redefine only one of those
  methods;
* `all:` to specify which condition all elements of produced collection should satisfy to coerce.

Example of the latter:

```ruby
Hash.include IdempotentEnumerable
Hash.idempotent_enumerable.constructor = :[]
# only convert back to hash if `map` have returned array of pairs
Hash.idempotent_enumerable.redefine_map! all: ->(e) { e.is_a?(Array) && e.count == 2 }
{a: 1, b: 2}.map(&:join)
# => ["a1", "b2"]  -- no coercion
{a: 1, b: 2}.map { |k, v| [k.to_s, v.to_s] }
# => {"a"=>"1", "b"=>"2"} -- coercion
```

## Performance penalty

...is, of course, present, yet not that awful (depends on your standards).

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

## Author

[Victor Shepelev](http://zverok.github.io/)

## License

MIT
