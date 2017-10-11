require 'rspec/its'

require 'idempotent_enumerable'

RSpec.describe IdempotentEnumerable do
  let(:collection_class) {
    Class.new {
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
  describe '#max(n)'
  describe '#max_by(n)'
  describe '#min(n)'
  describe '#min_by(n)'
  describe '#partition'
  describe '#sort'
  describe '#sort_by' do
    subject { collection.sort_by { |i| -i } }

    it { is_expected.to be_a collection_class }
    its(:to_a) { is_expected.to eq [5, 4, 3, 2, 1] }
  end

  describe '#take'
  describe '#take_while'
  describe '#uniq'

  describe '#reject' do
    subject { collection.reject(&:odd?) }

    it { is_expected.to be_a collection_class }
    its(:to_a) { is_expected.to eq [2, 4] }
  end

  describe '#select' do
    subject { collection.select(&:odd?) }

    it { is_expected.to be_a collection_class }
    its(:to_a) { is_expected.to eq [1, 3, 5] }
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
