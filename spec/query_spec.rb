require 'spec_helper'

describe 'Querying resources', type: :request do
  let!(:comments) { create_list :comment, 3 }

  it 'retrieves a resource' do
    get "/api/v1/comments/#{comments.first.id}"
    expect(json['data']['id']).to eq(comments.first.id.to_s)
  end

  it 'retrieves a collection' do
    get '/api/v1/comments'
    expect(json['data']).to respond_to(:any?)
  end

  describe '#record_scope' do
    context 'when scope provided is []' do
      before do
        API::V1::CommentsController.instance_eval do
          define_method :record_scope do |type|
            case type
            when :comments
              []
            else
              scope
            end
          end
        end
      end

      after do
        API::V1::CommentsController.instance_eval do
          remove_method :record_scope
        end
      end

      it 'responds with empty collection' do
        get "/api/v1/comments"
        expect(json['data'].count).to eq(0)
      end
    end
  end

  context 'when records do not exist' do
    let!(:nonexistent_id) { comments.first.id }
    before { Comment.destroy_all }

    context '/:id' do
      before { get "/api/v1/comments/#{nonexistent_id}" }

      it 'responds with 404' do
        expect(response.status).to eq(404)
      end

      it 'responds with appropriate message' do
        expect(json['errors'][0]['detail']).to eq("Could not find comment with id: '#{nonexistent_id}'")
      end
    end

    context '/' do
      it 'returns an empty collection' do
        get '/api/v1/comments'
        expect(json['data']).to be_empty
      end
    end
  end

  describe 'pagination' do
    it 'should return the correct number of records per page' do
      get '/api/v1/comments?page[size]=2'
      expect(json['data'].count).to eq(2)
    end

    it 'should return the correct page' do
      get '/api/v1/comments?page[size]=1&page[number]=2&sort=-body'
      expect(json['data'].first['id']).to eq(Comment.order(body: :desc).first(2)[1].id.to_s)
    end

    context 'when no page size is provided' do
      before do
        @default_page_size = Caprese.config.default_page_size
        Caprese.config.default_page_size = 2
      end

      it 'returns the default page size' do
        get '/api/v1/comments'
        expect(json['data'].count).to eq(Caprese.config.default_page_size)
      end

      after do
        Caprese.config.default_page_size = @default_page_size
      end
    end

    context 'when page size is above maximum' do
      before do
        @max_page_size = Caprese.config.max_page_size
        Caprese.config.max_page_size = 1
      end

      it 'returns the max page size' do
        get '/api/v1/comments?page[size]=10'
        expect(json['data'].count).to eq(Caprese.config.max_page_size)
      end

      after do
        Caprese.config.max_page_size = @max_page_size
      end
    end

    context 'limit and offset' do
      it 'applies the limit' do
        get '/api/v1/comments?limit=1'
        expect(json['data'].count).to eq(1)
      end

      it 'applies the offset' do
        get '/api/v1/comments?offset=2'
        expect(json['data'][0]['id']).to eq(Comment.offset(2).first.id.to_s)
      end

      context 'when offset is negative' do
        it 'starts from end of the scope' do
          get '/api/v1/comments?offset=-1&limit=1'
          expect(json['data'][0]['id']).to eq(Comment.last.id.to_s)
        end
      end
    end
  end

  describe 'sorting' do
    it 'should return a correctly ascending collection' do
      get '/api/v1/comments?sort=body'
      Comment.reorder(body: :asc).each_with_index do |order, index|
        expect(json['data'][index]['id']).to eq(order.id.to_s)
      end
    end

    it 'should return a correctly descending collection' do
      get '/api/v1/comments?sort=-body'
      Comment.reorder(body: :desc).each_with_index do |order, index|
        expect(json['data'][index]['id']).to eq(order.id.to_s)
      end
    end
  end

  describe 'filtering' do
    it 'should return a correctly filtered collection' do
      get "/api/v1/comments?filter[body]=#{URI.escape(comments.last.body)}"
      expect(json['data'].count).to eq(1)
      expect(json['data'].first['id']).to eq(comments.last.id.to_s)
    end
  end

  describe 'fields' do
    it 'should return only the fields specified' do
      get '/api/v1/comments?fields[comments]=created_at,body'
      expect(json['data'][0]['attributes']['created_at']).to_not be_nil
      expect(json['data'][0]['attributes']['body']).to_not be_nil
      expect(json['data'][0]['attributes']['updated_at']).to be_nil
    end

    context 'when specifying nested fields' do
      it 'returns only the fields specified' do
        get '/api/v1/comments?include=post&fields[post]=created_at'
        expect(json['included'][0]['attributes']['created_at']).to_not be_nil
        expect(json['included'][0]['attributes']['updated_at']).to be_nil
      end
    end
  end

  describe 'include' do
    context 'when specifying nested association' do
      it 'should include a full association' do
        get '/api/v1/comments?page[size]=1&include=post'

        post_params = json['included'].detect{ |r| r['type'] == 'posts' }

        expect(post_params['id']).to eq(comments.first.post.id.to_s)
        expect(post_params['attributes']['title']).to eq(comments.first.post.title)
      end

      context 'when deep nesting' do
        subject(:resource) { comments.first.post }

        it 'return all associations specified' do
          get '/api/v1/comments?page[size]=1&include=post.user'

          post_params = json['included'].detect { |r| r['type'] == 'posts' }
          user_params = json['included'].detect { |r| r['type'] == 'users' }

          expect(post_params['id']).to eq(resource.id.to_s)
          expect(post_params['attributes']['title']).to eq(resource.title)

          expect(user_params['id']).to eq(resource.user.id.to_s)
          expect(user_params['attributes']['name']).to eq(resource.user.name)
        end
      end
    end
  end
end
