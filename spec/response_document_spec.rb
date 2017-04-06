require 'spec_helper'

describe 'Resource document structure', type: :request do
  let!(:comments) { create_list :comment, 3 }

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

  describe 'meta' do
    before do
      API::V1::CommentsController.send :define_method, :add_meta_tag do
        meta[:tag_1] = 100
        meta[:tag_2] = 'tagged'
      end
      API::V1::CommentsController.before_query(:add_meta_tag)
    end

    after do
      API::V1::CommentsController.instance_variable_set('@before_query_callbacks', [])
    end

    before { get '/api/v1/comments/' }

    it 'adds meta tags to the response document' do
      expect(json['meta']['tag_1']).to eq(100)
      expect(json['meta']['tag_2']).to eq('tagged')
    end
  end

  describe 'links' do
    include Rails.application.routes.url_helpers

    before { Rails.application.routes.default_url_options[:host] = 'http://www.example.com' }

    before { get "/api/v1/#{resource_path}/#{resource.id}" }

    subject(:resource) { comments.first }
    let(:resource_path) { resource.class.name.underscore.pluralize }

    it 'includes self link' do
      expect(json['data']['links']['self']).to eq(api_v1_comment_url(resource))
    end

    # TODO: Implement and spec only_path option

    context 'when resource is serialized by parent resource model serializer' do
      subject(:resource) { create :image }
      let(:resource_path) { 'attachments' }

      it 'uses the parent resource model link' do
        expect(json['data']['links']['self']).to eq(api_v1_attachment_url(resource))
      end
    end
  end

  describe 'relationships' do
    context 'when scoping relationships' do
      let(:post) { create :post }
      let!(:comments)       { create_list :comment, 2, post: post, user: post.user }
      let!(:other_comments) { create_list :comment, 1, post: post, user: create(:user) }

      before do
        API::V1::PostSerializer.instance_eval do
          define_method :relationship_scope do |name, scope|
            case name
            when :comments
              scope.where(user: object.user)
            else
              scope
            end
          end
        end
      end

      after do
        API::V1::PostSerializer.instance_eval do
          remove_method :relationship_scope
        end
      end

      before { get "/api/v1/posts/#{post.id}?include=comments" }

      it 'only includes scoped relationship items' do
        expect(json['included'].count).to eq(2)
      end
    end

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

  describe 'aliasing' do
    describe 'attribute mocking' do
      before do
        Comment.instance_eval do
          define_method :caprese_is_attribute? do |name|
            %w(not_attribute).include?(name.to_s)
          end
        end

        API::V1::CommentsController.send :define_method, :add_error do |resource|
          resource.errors.add(:not_attribute, :blank)
        end
        API::V1::CommentsController.before_create(:add_error)
      end

      after do
        API::V1::CommentsController.instance_variable_set('@before_create_callbacks', [])

        Comment.instance_eval do
          remove_method :caprese_is_attribute?
        end
      end

      before { post '/api/v1/comments', { data: { type: 'comments' } } }

      it 'indicates that the alias is an attribute' do
        expect(json['errors'][0]['source']['pointer']).to eq('/data/attributes/not_attribute')
      end
    end

    describe 'aliasing an attribute' do
      before do
        Comment.instance_eval do
          def caprese_field_aliases
            {
              content: :body
            }
          end
        end
        API::V1::CommentSerializer.instance_eval do
          attributes :content
        end
      end

      after do
        Comment.instance_eval do
          def caprese_field_aliases
            {}
          end
        end

        API::V1::CommentSerializer.instance_eval do
          self._attributes_data = _attributes_data.except(:content)
        end
      end

      describe 'get' do
        before { get "/api/v1/comments#{query_str}" }
        let(:query_str) { '' }

        it 'aliases attribute' do
          expect(json['data'][0]['attributes']['content']).not_to be_nil
        end

        context 'filtering' do
          let(:filtered) { create :comment, body: '123456abc' }

          let(:query_str) { "?filter[content]=#{filtered.body}" }

          it 'filters by alias' do
            expect(json['data'].count).to eq(1)
          end
        end

        context 'select' do
          let(:query_str) { '?fields[comments]=content' }

          it 'selects the aliased field' do
            expect(json['data'][0]['attributes']['content']).not_to be_nil
          end

          it 'does not select other fields' do
            expect(json['data'][0]['attributes']['created_at']).to be_nil
          end
        end

        context 'sort' do
          let(:query_str) { '?sort=-content' }

          it 'sorts by the aliased field' do
            expect(json['data'].map { |c| c['id'].to_i }).to match(Comment.order(body: :desc).ids)
          end
        end
      end

      describe 'post' do
        before do
          API::V1::CommentsController.class_eval do
            def permitted_create_params
              [:content, :user, post: [:title, user: [:name]], rating: [:value]]
            end
          end
        end

        after do
          API::V1::CommentsController.class_eval do
            def permitted_create_params
              [:body, :user, post: [:title, user: [:name]], rating: [:value]]
            end
          end
        end

        before { post '/api/v1/comments', { data: data } }
        let(:content) { 'mah awesome body' }

        let(:data) do
          {
            type: 'comments',
            attributes: {
              content: content
            },
            relationships: {
              post: {
                data: { type: 'posts', id: comments.first.post.id.to_s }
              },
              user: {
                data: { type: 'users', id: comments.first.user.id.to_s }
              }
            }
          }
        end

        it 'converts aliased attribute' do
          expect(Comment.last.body).to eq(content)
        end
      end
    end

    describe 'aliasing a relationship' do
      before do
        Comment.instance_eval do
          def caprese_field_aliases
            {
              article: :post
            }
          end
        end
        API::V1::CommentSerializer.instance_eval do
          belongs_to :article
        end
      end

      after do
        Comment.instance_eval do
          def caprese_field_aliases
            {}
          end
        end
        API::V1::CommentSerializer.instance_eval do
          self._reflections = _reflections.except(:article)
        end
      end

      describe 'get' do
        include Rails.application.routes.url_helpers

        before { Rails.application.routes.default_url_options[:host] = 'http://www.example.com' }

        before { get "/api/v1/comments#{query_str}" }
        let(:query_str) { '' }

        it 'aliases relationship' do
          expect(json['data'][0]['relationships']['article']).not_to be_nil
        end

        it 'aliases relationship links' do
          expect(json['data'][0]['relationships']['article']['links']['self']).to eq(
            relationship_definition_api_v1_comment_url(
              comments.first,
              relationship: 'article'
            )
          )
        end

        context 'include' do
          let(:query_str) { '?include=article' }

          it 'includes aliased relationship' do
            expect(json['included'].map { |t| t['type'] }).to include('posts')
          end
        end
      end

      describe 'post' do
        before do
          API::V1::CommentsController.class_eval do
            def permitted_create_params
              [:body, :user, article: [:title, user: [:name]], rating: [:value]]
            end
          end
        end

        after do
          API::V1::CommentsController.class_eval do
            def permitted_create_params
              [:body, :user, post: [:title, user: [:name]], rating: [:value]]
            end
          end
        end

        before { post '/api/v1/comments', { data: data } }
        let(:article) { create :post }

        let(:data) do
          {
            type: 'comments',
            attributes: {
              body: 'My body'
            },
            relationships: {
              article: {
                data: { type: 'posts', id: article.id.to_s }
              },
              user: {
                data: { type: 'users', id: comments.first.user.id.to_s }
              }
            }
          }
        end

        it 'converts aliased relationship' do
          expect(Comment.last.post).to eq(article)
        end
      end

      describe 'relationship endpoints' do
        let(:comment) { comments.first }

        describe 'get data' do
          before { get "/api/v1/comments/#{comment.id}/article" }

          it 'responds with aliased relationship data' do
            expect(json['data']['type']).to eq('posts')
          end
        end

        describe 'get definition' do
          before { get "/api/v1/comments/#{comment.id}/relationships/article" }

          it 'responds with aliased relationship data' do
            expect(json['data']['type']).to eq('posts')
          end
        end

        describe 'update definition' do
          before do
            API::V1::CommentsController.class_eval do
              def permitted_update_params
                [:content, :user, article: [:title, user: [:name]], rating: [:value]]
              end
            end
          end

          after do
            API::V1::CommentsController.class_eval do
              def permitted_update_params
                [:body, :user, post: [:title, user: [:name]], rating: [:value]]
              end
            end
          end

          before { patch "/api/v1/comments/#{comment.id}/relationships/article", { data: data } }

          let(:data) do
            [
              {
                type: 'posts', id: my_post.id.to_s
              }
            ]
          end

          let(:other_comment) { Comment.where.not(id: comment.id).first }
          let(:my_post) { other_comment.post }

          before { comment.reload && other_comment.reload }

          it 'persists the aliased type resource relationship' do
            expect(comment.post).to eq(my_post)
          end
        end
      end
    end

    describe 'aliasing an attribute of an aliased relationship' do
      before do
        Comment.instance_eval do
          def caprese_field_aliases
            {
              article: :post
            }
          end
        end
        Post.instance_eval do
          def caprese_field_aliases
            {
              name: :title
            }
          end

          def caprese_type
            :article
          end
        end
        API::V1::CommentSerializer.instance_eval do
          belongs_to :article
        end
        API::V1::PostSerializer.instance_eval do
          attributes :name
        end
        API::V1::ApplicationController.class_eval do
          def resource_type_aliases
            {
              articles: :posts
            }
          end
        end
      end

      after do
        Comment.instance_eval do
          def caprese_field_aliases
            {}
          end
        end

        Post.instance_eval do
          def caprese_field_aliases
            {}
          end
        end

        API::V1::CommentSerializer.instance_eval do
          self._reflections = _reflections.except(:article)
        end
        API::V1::PostSerializer.instance_eval do
          self._attributes_data = _attributes_data.except(:name)
        end

        API::V1::ApplicationController.class_eval do
          def resource_type_aliases
            {}
          end
        end
      end

      describe 'get' do
        before { get "/api/v1/comments#{query_str}" }
        let(:query_str) { '?include=article' }

        it 'aliases attribute' do
          expect(json['included'][0]['attributes']['name']).not_to be_nil
        end

        context 'select' do
          let(:query_str) { '?include=article&fields[articles]=name' }

          it 'selects the aliased field' do
            expect(json['included'][0]['attributes']['name']).not_to be_nil
          end

          it 'does not select other fields' do
            expect(json['included'][0]['attributes']['created_at']).to be_nil
          end
        end
      end

      # TODO: Add specs for POST alias attribute of aliased relationship
      # describe 'post'
    end

    # TODO: Add specs for POST alias relationship of aliased relationship

    describe 'aliasing a type' do
      before do
        Comment.instance_eval do
          def caprese_type
            :review
          end
        end

        API::V1::ApplicationController.class_eval do
          def resource_type_aliases
            {
              reviews: :comments
            }
          end
        end
      end

      after do
        Comment.instance_eval do
          def caprese_type
            :comment
          end
        end

        API::V1::ApplicationController.class_eval do
          def resource_type_aliases
            {}
          end
        end
      end

      describe 'get' do
        before { get "/api/v1/comments#{query_str}" }
        let(:query_str) { '' }

        it 'aliases relationship' do
          expect(json['data'][0]['type']).to eq('reviews')
        end

        context 'select' do
          let(:query_str) { '?fields[reviews]=body' }

          it 'selects the fields' do
            expect(json['data'][0]['attributes']['body']).not_to be_nil
          end

          it 'does not select the other fields' do
            expect(json['data'][0]['attributes']['created_at']).to be_nil
          end
        end
      end

      describe 'post' do
        before { post "/api/v1/#{type}", { data: data } }

        let(:type) { 'comments' }

        let(:data) do
          {
            type: 'reviews',
            attributes: {
              body: 'abcdef123456'
            },
            relationships: {
              article: {
                data: { type: 'posts', id: Post.last.id.to_s }
              },
              user: {
                data: { type: 'users', id: comments.first.user.id.to_s }
              }
            }
          }
        end

        it 'persists the aliased typed resource' do
          expect(Comment.last.body).to eq('abcdef123456')
        end

        context 'as relationship' do
          let(:type) { 'posts' }
          let(:comment) { create :comment }

          let(:data) do
            {
              type: 'posts',
              attributes: {
                title: 'a title'
              },
              relationships: {
                comments: {
                  data: [{ type: 'reviews', id: comment.id.to_s }]
                },
                user: {
                  data: { type: 'users', id: comments.first.user.id.to_s }
                }
              }
            }
          end

          it 'persists the aliased typed relationship resource' do
            expect(Post.last.comments.first).to eq(comment)
          end
        end
      end

      describe 'relationship endpoints' do
        let(:my_post) { comments.first.post }

        describe 'get data' do
          before { get "/api/v1/posts/#{my_post.id}/comments" }

          it 'aliases relationship resource type' do
            expect(json['data'].select { |c| c['type'] == 'reviews' }.count).to eq(my_post.comments.size)
          end
        end

        describe 'get definition' do
          before { get "/api/v1/posts/#{my_post.id}/relationships/comments" }

          it 'aliases relationship resource type' do
            expect(json['data'].select { |c| c['type'] == 'reviews' }.count).to eq(my_post.comments.size)
          end
        end

        describe 'update definition' do
          before { patch "/api/v1/posts/#{my_post.id}/relationships/comments", { data: data } }

          let(:data) do
            [
              {
                type: 'reviews', id: comment.id.to_s
              }
            ]
          end

          let(:other_post) { Post.where.not(id: my_post.id).first }
          let(:comment) { other_post.comments.create(body: 'done', user: Post.first.user) }

          before { my_post.reload && other_post.reload }

          it 'persists the aliased type resource relationship' do
            expect(my_post.comments.first).to eq(comment)
          end
        end
      end

      describe 'included' do
        before { get "/api/v1/posts?include=comments" }

        it 'includes the aliased type resources' do
          expect(json['included'].select { |c| c['type'] == 'reviews' }.count).to eq(Comment.count)
        end
      end
    end
  end
end
