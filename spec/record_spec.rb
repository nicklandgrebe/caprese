require 'spec_helper'

describe Caprese::Record, type: :model do
  let(:record) { create :post }

  before { Caprese::Record.caprese_style_errors = true }
  after { Caprese::Record.caprese_style_errors = false }

  describe '#errors' do
    before { record.errors.add(field) }

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
    end
  end
end