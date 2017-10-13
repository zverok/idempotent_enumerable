require 'coveralls'
Coveralls.wear!

require 'prime'

require 'rspec/its'
require 'saharspec/its/map'

require 'idempotent_enumerable'

RSpec.describe IdempotentEnumerable do
  shared_examples 'return collection' do |method, *arg, block, expected, empty: nil, since: nil, updated: nil|
    if !since && !updated || RUBY_VERSION >= (since || updated)
      describe "##{method}" do
        subject { collection.send(method, *arg, &block) }

        it { is_expected.to be_a collection_class }
        its(:to_a) { is_expected.to eq expected }
        if empty
          context 'without arguments' do
            specify { expect(collection.send(method, &block)).to eq empty }
          end
        end

        if block
          context 'without block' do
            subject { collection.send(method, *arg) }

            it { is_expected.to be_a Enumerator }
          end
        end
      end
    elsif since
      it { is_expected.not_to respond_to(method) }
    end
  end

  shared_examples 'return array of collections' do |method, *arg, block, expected, blockless: true, since: nil|
    if !since || RUBY_VERSION >= since
      describe "##{method}" do
        subject { collection.send(method, *arg, &block).to_a }

        it { is_expected.to all be_a collection_class }
        its_map(:to_a) { is_expected.to eq expected }

        if block && blockless
          context 'without block' do
            subject { collection.send(method, *arg) }

            it { is_expected.to be_a Enumerator }
          end
        end
      end
    elsif since
      it { is_expected.not_to respond_to(method) }
    end
  end

  subject(:collection) { collection_class.new((1..5).to_a) }

  let(:collection_class) {
    Class.new {
      def self.inspect
        '<Test Class>'
      end

      def initialize(ary)
        @ary = ary.dup
      end

      def each(&block)
        @ary.each(&block)
      end

      def to_a
        @ary
      end

      include IdempotentEnumerable
    }
  }

  it_behaves_like 'return array of collections', :chunk_while, ->(a, b) { (a + b).prime? },
                  [[1, 2, 3, 4], [5]], blockless: false, since: '2.3'
  it_behaves_like 'return collection', :drop, 4, nil, [5]
  it_behaves_like 'return collection', :drop_while, :odd?, [2, 3, 4, 5]
  it_behaves_like 'return array of collections', :each_cons, 2, nil,
                  [[1, 2], [2, 3], [3, 4], [4, 5]]
  it_behaves_like 'return array of collections', :each_slice, 2, nil, [[1, 2], [3, 4], [5]]
  it_behaves_like 'return collection', :first, 2, nil, [1, 2], empty: 1
  it_behaves_like 'return collection', :grep, :odd?.to_proc, nil, [1, 3, 5]
  it_behaves_like 'return collection', :grep_v, :odd?.to_proc, nil, [2, 4], since: '2.3'
  it_behaves_like 'return collection', :max, 3, nil, [5, 4, 3], empty: 5, updated: '2.2'
  it_behaves_like 'return collection', :max_by, 3, :-@, [1, 2, 3], empty: 1, updated: '2.2'
  it_behaves_like 'return collection', :min, 3, nil, [1, 2, 3], empty: 1, updated: '2.2'
  it_behaves_like 'return collection', :min_by, 3, :-@, [5, 4, 3], empty: 5, updated: '2.2'
  it_behaves_like 'return array of collections', :partition, :odd?, [[1, 3, 5], [2, 4]]
  it_behaves_like 'return collection', :reject, :odd?, [2, 4]
  it_behaves_like 'return collection', :select, :odd?, [1, 3, 5]
  it_behaves_like 'return array of collections', :slice_after, :even?.to_proc, nil,
                  [[1, 2], [3, 4], [5]], since: '2.2'
  it_behaves_like 'return array of collections', :slice_after, :even?,
                  [[1, 2], [3, 4], [5]], blockless: false, since: '2.2'
  it_behaves_like 'return array of collections', :slice_before, :even?.to_proc, nil,
                  [[1], [2, 3], [4, 5]]
  it_behaves_like 'return array of collections', :slice_before, :even?,
                  [[1], [2, 3], [4, 5]], blockless: false
  it_behaves_like 'return array of collections', :slice_when, ->(a, b) { ((a + b) % 3).zero? },
                  [[1], [2, 3, 4], [5]], blockless: false, since: '2.2'
  it_behaves_like 'return collection', :sort, nil, [1, 2, 3, 4, 5]
  it_behaves_like 'return collection', :sort_by, ->(i) { -i }, [5, 4, 3, 2, 1]
  it_behaves_like 'return collection', :take, 2, nil, [1, 2]
  it_behaves_like 'return collection', :take_while, :odd?, [1]

  describe '#chunk' do
    subject { collection.chunk(&:odd?) }

    its_map(:first) { are_expected.to eq [true, false, true, false, true] }
    its_map(:last) { are_expected.to all be_a collection_class }
    its_map(:'last.to_a') { are_expected.to eq [[1], [2], [3], [4], [5]] }
  end

  describe '#group_by' do
    subject { collection.group_by(&:odd?) }

    its(:keys) { are_expected.to eq [true, false] }
    its(:values) { are_expected.to all be_a collection_class }
  end

  if RUBY_VERSION >= '2.4'
    context 'non-unique collection' do
      subject(:collection) { collection_class.new([1, 2, 1, 3, 2]) }

      it_behaves_like 'return collection', :uniq, nil, [1, 2, 3]
    end
  else
    it { is_expected.not_to respond_to(:uniq) }
  end

  context 'when #each accepts arguments' do
    before {
      class << collection
        def each(i)
          return to_enum(:each, i) unless block_given?
          @ary.each { |e| yield(e + i) }
        end
      end
    }
    subject { collection.select(1, &:odd?) }

    it { is_expected.to be_a collection_class }
    its(:to_a) { is_expected.to eq [3, 5] } # 2 + 1 & 4 + 1

    # TODO: methods with argument (grep) and optional argument (min)
  end

  describe 'as your regular enumerable' do
    it { is_expected.to be_a Enumerable }
    specify { expect(collection.all?(&:odd?)).to be_falsey }
    specify { expect(collection.any?(&:odd?)).to be_truthy }
  end

  describe 'settings' do
    describe 'custom constructor' do
      subject { collection.select(&:odd?) }

      before {
        collection_class.module_eval {
          def self.from_a(ary)
            new(*ary)
          end

          def initialize(*ary)
            @ary = ary
          end

          idempotent_enumerable.constructor = :from_a
        }
      }
      let(:collection) { collection_class.new(1, 2, 3, 4, 5) }

      it { is_expected.to be_a collection_class }
      its(:to_a) { is_expected.to eq [1, 3, 5] }
    end

    describe 'update method list' do
      context 'redefine all' do
        before {
          collection_class.module_eval {
            idempotent_enumerable.redefine_map!
          }
        }

        context '#map' do
          subject { collection.map(&:to_s) }

          it { is_expected.to be_a collection_class }
          its(:to_a) { is_expected.to eq %w[1 2 3 4 5] }
        end

        context '#flat_map' do
          subject { collection.flat_map { |i| [i, i] } }

          it { is_expected.to be_a collection_class }
          its(:to_a) { is_expected.to eq [1, 1, 2, 2, 3, 3, 4, 4, 5, 5] }
        end
      end

      context 'conditional' do
        before {
          collection_class.module_eval {
            idempotent_enumerable.redefine_map! all: ->(i) { i.is_a?(Numeric) }
          }
        }

        context 'matches' do
          subject { collection.map(&:-@) }

          it { is_expected.to be_a collection_class }
          its(:to_a) { is_expected.to eq [-1, -2, -3, -4, -5] }
        end

        context 'not matches' do
          subject { collection.map(&:to_s) }

          it { is_expected.to eq %w[1 2 3 4 5] }
        end
      end

      context 'selective' do
        before {
          collection_class.module_eval {
            idempotent_enumerable.redefine_map! only: :map
          }
        }

        context '#map' do
          subject { collection.map(&:to_s) }

          it { is_expected.to be_a collection_class }
          its(:to_a) { is_expected.to eq %w[1 2 3 4 5] }
        end

        context '#flat_map' do
          subject { collection.flat_map { |i| [i, i] } }

          it { is_expected.to eq [1, 1, 2, 2, 3, 3, 4, 4, 5, 5] }
        end
      end
    end
  end
end
