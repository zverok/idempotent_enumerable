require 'rspec/its'

require 'idempotent_enumerable'

RSpec.describe IdempotentEnumerable do
  shared_examples 'method' do |method, *arg, block, expected|
    context method do
      subject { collection.send(method, *arg, &block) }

      it { is_expected.to be_a collection_class }
      its(:to_a) { is_expected.to eq expected }
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
  describe '#drop'
  describe '#drop_while'
  describe '#first(n)'
  describe '#grep'
  describe '#grep_v'
  describe '#group_by'
  describe '#partition'

  it_behaves_like 'method', :grep, :odd?.to_proc, nil, [1, 3, 5]
  it_behaves_like 'method', :grep_v, :odd?.to_proc, nil, [2, 4]
  it_behaves_like 'method', :max, 3, nil, [5, 4, 3]
  it_behaves_like 'method', :max_by, 3, ->(i) { -i }, [1, 2, 3]
  it_behaves_like 'method', :min, 3, nil, [1, 2, 3]
  it_behaves_like 'method', :min_by, 3, ->(i) { -i }, [5, 4, 3]
  it_behaves_like 'method', :reject, :odd?, [2, 4]
  it_behaves_like 'method', :select, :odd?, [1, 3, 5]
  it_behaves_like 'method', :sort, nil, [1, 2, 3, 4, 5]
  it_behaves_like 'method', :sort_by, ->(i) { -i }, [5, 4, 3, 2, 1]

  describe '#take'
  describe '#take_while'
  describe '#uniq'

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
