require 'spec_helper'

describe 'Managing relationships of resources', type: :request do
  subject(:original_comment_count) { 2 }
  subject(:resource) { create :post, :with_comments, comment_count: original_comment_count }

  context 'retrieving relationship definition' do
    before { get "/api/v1/posts/#{resource.id}/relationships/#{relationship}#{query_str}" }

    let(:query_str) { '' }

    context 'one-to-one' do
      subject(:relationship) { 'user' }

      it 'responds with correct resource identifier' do
        expect(json['data']['type']).to eq('users')
        expect(json['data']['id']).to eq(resource.user.id.to_s)
      end
    end

    context 'one-to-many' do
      subject(:relationship) { 'comments' }

      it 'responds with correct resource identifiers' do
        expect(json['data'].count).to eq(resource.comments.count)
        expect(json['data'][0]['type']).to eq('comments')
        expect(json['data'][0]['id']).to eq(resource.comments.first.id.to_s)
      end
    end

    context 'when relationship doesnt exist' do
      subject(:relationship) { 'invalid' }

      it 'responds with 404' do
        expect(response.status).to eq(404)
      end

      it 'responds with appropriate message' do
        expect(json['errors'][0]['detail']).to eq("Could not find relationship with name: 'invalid'")
      end
    end

    context 'include' do
      let(:relationship) { 'user' }
      let(:query_str) { '?include=posts' }

      it 'includes specified relationships' do
        expect(json['included'].map { |i| i['type'] }).to include('posts')
      end
    end
  end

  context 'updating relationship definition' do
    # Update the relationship data
    before do
      send(
        verb,
        "/api/v1/#{resource.class.name.downcase.pluralize}/#{resource.id}/relationships/#{relationship}",
        { data: data }
      )
    end

    before { resource.reload }

    context 'one-to-one' do
      subject(:verb) { 'patch' }

      context 'when assigning to relationship' do
        subject(:relationship) { 'user' }
        subject(:relationship_resource) { create :user }
        subject(:data) { { id: relationship_resource.id, type: 'users' } }

        it 'responds with 204' do
          expect(response.status).to eq(204)
        end

        it 'assigns to the relationship' do
          expect(resource.send(relationship)).to eq(relationship_resource)
        end
      end

      context 'when clearing relationship' do
        subject(:resource) { create :comment }
        subject(:relationship) { 'user' }
        subject(:data) { nil }

        it 'responds with 204' do
          expect(response.status).to eq(204)
        end

        it 'clears the relationship' do
          expect(resource.send(relationship)).to eq(nil)
        end
      end

      context 'when relationship cannot be changed' do
        subject(:relationship) { 'user' }
        subject(:data) { nil }

        it 'responds with 403' do
          expect(response.status).to eq(403)
        end

        it 'does not modify the relationship' do
          expect(resource.send(relationship)).to_not eq(nil)
        end
      end
    end

    context 'one-to-many' do
      subject(:relationship) { 'comments' }
      subject(:relationship_resource) { create :comment }
      subject(:data) { { id: relationship_resource.id, type: 'comments' } }

      context 'when assigning to relationship' do
        subject(:verb) { 'patch' }

        it 'responds with 204' do
          expect(response.status).to eq(204)
        end

        it 'assigns to the relationship correctly' do
          expect(resource.comments.count).to eq(1)
          expect(resource.comments.first).to eq(relationship_resource)
        end

        context 'relationship resource cannot be found' do
          subject(:data) { { id: relationship_resource.id + 1000, type: 'comments' } }

          it 'responds with 422' do
            expect(response.status).to eq(422)
          end

          it 'responds with error source pointer to data' do
            expect(json['errors'][0]['source']['pointer']).to eq('/data')
          end

          it 'responds with error code not_found' do
            expect(json['errors'][0]['code']).to eq('not_found')
          end
        end

        context 'relationship resource has no type' do
          subject(:data) { { id: relationship_resource.id } }

          it 'responds with 422' do
            expect(response.status).to eq(422)
          end

          it 'responds with error source pointer to data' do
            expect(json['errors'][0]['source']['pointer']).to eq('/data/type')
          end

          it 'responds with error code invalid' do
            expect(json['errors'][0]['code']).to eq('invalid')
          end
        end
      end

      context 'when clearing relationship' do
        subject(:verb) { 'patch' }
        subject(:data) { [] }

        it 'responds with 204' do
          expect(response.status).to eq(204)
        end

        it 'assigns to the relationship correctly' do
          expect(resource.comments.count).to eq(0)
        end
      end

      context 'when appending to relationship' do
        subject(:verb) { 'post' }

        it 'responds with 204' do
          expect(response.status).to eq(204)
        end

        it 'appends to the relationship correctly' do
          expect(resource.comments.count).to eq(original_comment_count + 1)
          expect(resource.comments.last).to eq(relationship_resource)
        end

        context 'when data nil' do
          let(:data) { nil }

          it 'responds with 422' do
            expect(response.status).to eq(422)
          end

          it 'responds with error source pointer to data' do
            expect(json['errors'][0]['source']['pointer']).to eq('/data')
          end

          it 'responds with error code invalid' do
            expect(json['errors'][0]['code']).to eq('invalid')
          end
        end
      end

      context 'when deleting from relationship' do
        subject(:verb) { 'delete' }
        subject(:relationship_resource) { resource.comments.first }

        it 'responds with 204' do
          expect(response.status).to eq(204)
        end

        it 'deletes from the relationship' do
          expect(resource.comments.count).to eq(original_comment_count - 1)
        end

        context 'when data nil' do
          let(:data) { nil }

          it 'responds with 422' do
            expect(response.status).to eq(422)
          end

          it 'responds with error source pointer to data' do
            expect(json['errors'][0]['source']['pointer']).to eq('/data')
          end

          it 'responds with error code invalid' do
            expect(json['errors'][0]['code']).to eq('invalid')
          end
        end
      end
    end

    context 'when relationship doesnt exist' do
      subject(:verb) { 'patch' }
      subject(:relationship) { 'invalid' }
      subject(:data) { { id: 100000, type: 'invalid' } }

      it 'responds with 404' do
        expect(response.status).to eq(404)
      end
    end
  end

  context 'retrieving relationship data' do
    include Rails.application.routes.url_helpers

    before { Rails.application.routes.default_url_options[:host] = 'http://www.example.com' }

    before { get "/api/v1/#{resource.class.name.downcase.pluralize}/#{resource.id}/#{relationship}#{query_str}" }

    let(:query_str) { '' }

    context 'one-to-one' do
      subject(:relationship) { 'user' }

      it 'responds with correct resource identifier' do
        expect(json['data']['type']).to eq('users')
        expect(json['data']['id']).to eq(resource.user.id.to_s)
      end

      it 'includes resource attributes' do
        expect(json['data']['attributes']).to be_instance_of(Hash)
      end

      it 'includes related link' do
        expect(json['links']['related']).to eq(api_v1_user_url(resource.user))
      end
    end

    context 'one-to-many' do
      subject(:relationship) { 'comments' }

      it 'responds with correct resource identifiers' do
        expect(json['data'].count).to eq(resource.comments.count)
        expect(json['data'][0]['type']).to eq('comments')
        expect(json['data'][0]['id']).to eq(resource.comments.first.id.to_s)
      end

      it 'includes resource attributes' do
        expect(json['data'][0]['attributes']).to be_instance_of(Hash)
      end

      context 'with relation id' do
        subject(:relationship) { "comments/#{resource.comments.first.id}" }

        it 'responds with correct resource identifier' do
          expect(json['data']['type']).to eq('comments')
          expect(json['data']['id']).to eq(resource.comments.first.id.to_s)
        end

        it 'includes related link' do
          expect(json['links']['related']).to eq(api_v1_comment_url(resource.comments.first))
        end
      end
    end

    context 'when relationship doesnt exist' do
      subject(:relationship) { 'invalid' }

      it 'responds with 404' do
        expect(response.status).to eq(404)
      end
    end

    context 'fields' do
      let(:relationship) { 'user' }
      let(:query_str) { '?fields[users]=name' }

      it 'only returns fields specified' do
        expect(json['data']['attributes']['name']).not_to be_nil
        expect(json['data']['attributes']['created_at']).to be_nil
      end
    end

    context 'include' do
      let(:relationship) { 'user' }
      let(:query_str) { '?include=posts' }

      it 'includes specified relationships' do
        expect(json['included'].map { |i| i['type'] }).to include('posts')
      end
    end
  end
end
