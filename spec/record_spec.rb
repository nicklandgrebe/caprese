require 'spec_helper'

describe Caprese::Record, type: :model do
  let(:record) { create :post }

  before { Caprese::Current.caprese_style_errors = true }
  after { Caprese::Current.caprese_style_errors = false }

  describe '#errors' do
    let(:options) { {} }
    before { record.errors.add(field, :too_fluffy, options) }

    let(:error) { record.errors.to_a.first }

    context 'when :base' do
      let(:field) { :base }

      it 'sets field title to model name' do
        expect(error.t[:field]).to eq('post')
      end
    end

    context 'when field' do
      let(:field) { :title }

      it 'sets field title to model name' do
        expect(error.t[:field]).to eq('title')
      end

      context 'with pluralized value' do
        context 'value 1' do
          let(:options) { { t: { count: 1 } } }

          subject { record.errors.full_messages.join }
          it { is_expected.to eq 'Title has one fluff, which is too much'}
        end

        context 'value 5' do
          let(:options) { { t: { count: 5 } } }

          subject { record.errors.full_messages.join }
          it { is_expected.to eq 'Title has 5 fluffs, which is way too much'}
        end
      end
    end
  end
end
