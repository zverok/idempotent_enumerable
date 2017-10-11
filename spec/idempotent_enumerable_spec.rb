require 'rspec/its'

require 'idempotent_enumerable'

RSpec.describe IdempotentEnumerable do
  shared_examples 'method' do |method, *arg, block, expected, empty: nil|
    describe "##{method}" do
      subject { collection.send(method, *arg, &block) }

      it { is_expected.to be_a collection_class }
      its(:to_a) { is_expected.to eq expected }
      if empty
        context 'without arguments' do
          specify { expect(collection.send(method, &block)).to eq empty }
        end
      end
    end
  end

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

  subject(:collection) { collection_class.new((1..5).to_a) }

  describe '#chunk'
  describe '#group_by'
  describe '#partition'

  it_behaves_like 'method', :drop, 4, nil, [5]
  it_behaves_like 'method', :drop_while, :odd?, [2, 3, 4, 5]
  it_behaves_like 'method', :first, 2, nil, [1, 2], empty: 1
  it_behaves_like 'method', :grep, :odd?.to_proc, nil, [1, 3, 5]
  it_behaves_like 'method', :grep_v, :odd?.to_proc, nil, [2, 4]
  it_behaves_like 'method', :max, 3, nil, [5, 4, 3], empty: 5
  it_behaves_like 'method', :max_by, 3, :-@, [1, 2, 3], empty: 1
  it_behaves_like 'method', :min, 3, nil, [1, 2, 3], empty: 1
  it_behaves_like 'method', :min_by, 3, :-@, [5, 4, 3], empty: 5
  it_behaves_like 'method', :reject, :odd?, [2, 4]
  it_behaves_like 'method', :select, :odd?, [1, 3, 5]
  it_behaves_like 'method', :sort, nil, [1, 2, 3, 4, 5]
  it_behaves_like 'method', :sort_by, ->(i) { -i }, [5, 4, 3, 2, 1]
  it_behaves_like 'method', :take, 2, nil, [1, 2]
  it_behaves_like 'method', :take_while, :odd?, [1]

  if RUBY_VERSION >= '2.4'
    context 'non-unique collection' do
      subject(:collection) { collection_class.new([1,2,1,3,2]) }
      it_behaves_like 'method', :uniq, nil, [1,2,3]
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

      subject { collection.select(&:odd?) }
      it { is_expected.to be_a collection_class }
      its(:to_a) { is_expected.to eq [1, 3, 5] }
    end

    describe 'update method list' do
    end
  end
end
