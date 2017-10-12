require 'rspec/its'
require 'saharspec/its/map'

require 'idempotent_enumerable'

RSpec.describe IdempotentEnumerable do
  shared_examples 'return collection' do |method, *arg, block, expected, empty: nil|
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
  end

  shared_examples 'return array of collections' do |method, *arg, block, expected|
    describe "##{method}" do
      subject { collection.send(method, *arg, &block).to_a }

      it { is_expected.to all be_a collection_class }
      its_map(:to_a) { is_expected.to eq expected }

      if block
        context 'without block' do
          subject { collection.send(method, *arg) }
          it { is_expected.to be_a Enumerator }
        end
      end
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

  describe '#chunk'
  describe '#chunk_while'
  describe '#slice_after'
  describe '#slice_before'
  describe '#slice_when'

  it_behaves_like 'return collection', :drop, 4, nil, [5]
  it_behaves_like 'return collection', :drop_while, :odd?, [2, 3, 4, 5]
  it_behaves_like 'return array of collections', :each_cons, 2, nil, [[1, 2], [2, 3], [3, 4], [4, 5]]
  it_behaves_like 'return array of collections', :each_slice, 2, nil, [[1, 2], [3, 4], [5]]
  it_behaves_like 'return collection', :first, 2, nil, [1, 2], empty: 1
  it_behaves_like 'return collection', :grep, :odd?.to_proc, nil, [1, 3, 5]
  it_behaves_like 'return collection', :grep_v, :odd?.to_proc, nil, [2, 4]
  it_behaves_like 'return collection', :max, 3, nil, [5, 4, 3], empty: 5
  it_behaves_like 'return collection', :max_by, 3, :-@, [1, 2, 3], empty: 1
  it_behaves_like 'return collection', :min, 3, nil, [1, 2, 3], empty: 1
  it_behaves_like 'return collection', :min_by, 3, :-@, [5, 4, 3], empty: 5
  it_behaves_like 'return array of collections', :partition, :odd?, [[1, 3, 5], [2, 4]]
  it_behaves_like 'return collection', :reject, :odd?, [2, 4]
  it_behaves_like 'return collection', :select, :odd?, [1, 3, 5]
  it_behaves_like 'return collection', :sort, nil, [1, 2, 3, 4, 5]
  it_behaves_like 'return collection', :sort_by, ->(i) { -i }, [5, 4, 3, 2, 1]
  it_behaves_like 'return collection', :take, 2, nil, [1, 2]
  it_behaves_like 'return collection', :take_while, :odd?, [1]

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
  end

  # TODO: what with "just enumerator" form of the methods?.. Enumerator#to_original or something?..

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

      let(:collection_class) {
        Class.new {
          def self.from_a(ary)
            new(*ary)
          end

          def initialize(*ary)
            @ary = ary
          end

          def each(&block)
            @ary.each(&block)
          end

          def to_a
            @ary
          end

          include IdempotentEnumerable
          idempotent_enumerable.constructor = :from_a
        }
      }
      let(:collection) { collection_class.new(1, 2, 3, 4, 5) }

      it { is_expected.to be_a collection_class }
      its(:to_a) { is_expected.to eq [1, 3, 5] }
    end

    describe 'update method list' do
      # map, flat_map
    end
  end
end
