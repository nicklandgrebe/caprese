require 'spec_helper'

describe 'Versioning helpers', type: :helper do
  describe '#version_module' do
    let!(:versioned_class) do
      API::V1::PostsController
    end

    let(:output) { versioned_class.version_module }

    it 'returns the versioning modules of the class' do
      expect(output).to eq('API::V1')
    end

    context 'config.isolate_namespace' do
      before { Caprese.config.isolated_namespace = API }
      after { Caprese.config.isolated_namespace = nil }

      it 'returns the versioning modules of the class without the isolated namespace' do
        expect(output).to eq('V1')
      end
    end
  end
end
