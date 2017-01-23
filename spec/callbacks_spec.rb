require 'spec_helper'

describe 'Requests with Callbacks', type: :request do
  describe '#before_query' do
    let!(:comments) do
      create_list :comment, 3
    end

    before do
      API::V1::CommentsController.send :define_method, :modify_query do |resource|
        query_params[:sort] = ['-body']
      end
      API::V1::CommentsController.before_query(:modify_query)
    end

    after do
      API::V1::CommentsController.instance_variable_set('@before_query_callbacks', [])
    end

    before { get '/api/v1/comments/' }

    it 'executes the callback before querying' do
      expect(json['data'][0]['attributes']['body']).to eq(Comment.order(body: :desc).first.body)
    end
  end

  describe '#before_create' do
    before do
      API::V1::CommentsController.send :define_method, :remove_body do |resource|
        resource.body = ''
      end
      API::V1::CommentsController.before_create(:remove_body)
    end

    after do
      API::V1::CommentsController.instance_variable_set('@before_create_callbacks', [])
    end

    before { post "/api/v1/#{type}/", { data: data } }

    subject(:data) do
      output = { type: type }
      output.merge!(attributes: attributes)
      output.merge!(relationships: relationships)
    end

    subject(:type) { 'comments' }
    subject(:attributes) { { body: 'One body' } }
    subject(:relationships) do
      {
        user: { data: { type: 'users', id: create(:user).id } },
        post: { data: { type: 'posts', id: create(:post).id } }
      }
    end

    it 'executes the callback before creating' do
      expect(json['errors'][0]['source']['pointer']).to eq('/data/attributes/body')
    end
  end

  describe '#after_create' do
    before do
      API::V1::CommentsController.send :define_method, :remove_body do |resource|
        resource.body = ''
      end
      API::V1::CommentsController.after_create(:remove_body)
    end

    after do
      API::V1::CommentsController.instance_variable_set('@before_create_callbacks', [])
    end

    before { post "/api/v1/#{type}/", { data: data } }

    subject(:data) do
      output = { type: type }
      output.merge!(attributes: attributes)
      output.merge!(relationships: relationships)
    end

    subject(:type) { 'comments' }
    subject(:attributes) { { body: 'One body' } }
    subject(:relationships) do
      {
        user: { data: { type: 'users', id: create(:user).id } },
        post: { data: { type: 'posts', id: create(:post).id } }
      }
    end

    it 'executes the callback before creating' do
      expect(json['data']['attributes']['body']).to eq('')
    end
  end

  describe 'on base controller' do
    let!(:comments) do
      create_list :comment, 3
    end

    before do
      API::ApplicationController.send :define_method, :set_page_size do
        query_params[:page] = { size: 1 }
      end
      API::ApplicationController.before_query(:set_page_size)
    end

    before { get '/api/v1/comments' }

    after do
      API::ApplicationController.instance_variable_set('@before_query_callbacks', [])
    end

    it 'executes the inherited callback' do
      expect(json['data'].count).to eq(1)
    end
  end
end
