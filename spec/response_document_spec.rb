require 'spec_helper'

describe 'Resource document structure', type: :request do
  let!(:comments) { create_list :comment, 1 }

  describe 'type' do
    before { get "/api/v1/#{resource.class.name.underscore.pluralize}/#{resource.id}" }

    subject(:resource) { comments.first }

    it 'uses the resource model name' do
      expect(json['data']['type']).to eq('comments')
    end

    context 'when resource is serialized by parent resource model serializer' do
      subject(:resource) { create :post, :with_attachments }

      it 'uses the parent resource model name' do
        expect(json['data']['relationships']['attachments']['data'][0]['type']).to eq('attachments')
      end
    end
  end

  describe 'links' do
    include Rails.application.routes.url_helpers

    before { Rails.application.routes.default_url_options[:host] = 'http://www.example.com' }

    it 'includes self link' do
      get "/api/v1/comments/#{comments.first.id}"
      expect(json['data']['links']['self']).to eq(api_v1_comment_url(comments.first))
    end

    # TODO: Implement and spec only_path option
  end

  describe 'relationships' do
    context 'when optimizing relationships' do
      before { Caprese.config.optimize_relationships = true }
      after { Caprese.config.optimize_relationships = false }

      before { get "/api/v1/comments/#{comments.first.id}#{query_str}" }

      context 'when association included' do
        subject(:query_str) { '?include=post' }

        it 'serializes the relationship data' do
          expect(json['data']['relationships']['post']['data']).not_to be_nil
        end
      end

      context 'when association not included' do
        subject(:query_str) { '' }

        it 'does not serialize the relationship data' do
          expect(json['data']['relationships']['post']['data']).to be_nil
        end
      end

      context 'when deep nesting' do
        subject(:post_params) { json['included'].detect { |r| r['type'] == 'posts' } }

        context 'when association included' do
          subject(:query_str) { '?include=post.user' }

          it 'serializes the relationship data' do
            expect(post_params['relationships']['user']['data']).not_to be_nil
          end
        end

        context 'when association not included' do
          subject(:query_str) { '?include=post' }

          it 'does not serialize the relationship data' do
            expect(json['data']['relationships']['user']['data']).to be_nil
          end
        end
      end
    end
  end
end
