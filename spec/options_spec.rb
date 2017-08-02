require 'spec_helper'

describe 'OPTIONS requests', type: :request do
  before do
    API::V1::PostsController.instance_eval do
      define_method :resource_schema do |post|
        {
          title: Fields.string.is_required,
          attachments: Fields.collection_of(Image, Video).shape({
            name: Fields.string.is_required,
            score: Fields.decimal.is_required
          }),
          comments: Fields.collection_of(Comment).custom(-> (prop_mutater) {
            if post && post.title == 'Random title'
              prop_mutater.alias_type(:subjects).count(4).is_required
            end
          }),
          ratings: Fields.collection_of(Rating).alias_type(:critiques).shape({
            value: Fields.integer.is_required
          }).custom(-> (prop_mutater)) {
            if post && (comments = post.user.comments).any?
              prop_mutater.for_each(comments, { |m, c|
                m.shape({
                  subject: Fields.resource(Comment).alias_type(:subjects).data(c)
                }).is_required(c.id % 2 == 0)
              })
            else
              prop_mutater.shape({
                subject: Fields.resource(Comment).alias_type(:subjects).is_required
              })
            end
          },
          user: Fields.resource(User).shape({
            name: Fields.string.is_required,
          }).is_required
        }
      end
    end

    options_data = { data: data } unless data.nil?
    options '/api/v1/posts', options_data
  end

  after do
    API::V1::PostsController.instance_eval do
      remove_method :schema
    end
  end

  let(:data) { nil }

  it 'responds with schema for that resource type' do
    expect(json['schema']).to eq({
      type: 'posts',
      attributes: {
        title: { type: 'strings', required: true }
      },
      relationships: {
        attachments: {
          schema: [{
            type: 'images',
            attributes: {
              name: { type: 'strings', required: true },
              score: { type: 'decimals', required: true }
            }
          }, {
            type: 'videos',
            attributes: {
              name: { type: 'strings', required: true },
              score: { type: 'decimals', required: true }
            }
          }]
        },
        comments: {
          schema: [{
            type: 'comments'
          }]
        },
        ratings: {
          schema: [{
            type: 'critiques',
            attributes: {
              value: { type: 'integers', required: true }
            },
            relationships: {
              subject: {
                schema: {
                  type: 'subjects',
                  required: true
                }
              }
            }
          }]
        },
        user: {
          schema: {
            type: 'users',
            required: true,
            attributes: {
              name: { type: 'strings', required: true }
            }
          }
        }
      }
    })
  end

  describe 'with data' do
    let(:data) do
      output = { type: 'posts' }
      output.merge!(attributes: attributes) unless attributes.nil?
      output.merge!(relationships: relationships) unless relationships.nil?
    end

    let(:attributes) { nil }
    let(:relationships) { nil }

    context 'attributes' do
      let(:attributes) do
        {
          title: 'Random title'
        }
      end

      it 'responds with options for those attributes' do
        expect(json['schema']).to eq({
          type: 'posts',
          attributes: {
            title: { type: 'strings', required: true }
          },
          relationships: {
            attachments: {
              schema: [{
                type: 'images',
                attributes: {
                  name: { type: 'strings', required: true },
                  score: { type: 'decimals', required: true }
                }
              }, {
                type: 'videos',
                attributes: {
                  name: { type: 'strings', required: true },
                  score: { type: 'decimals', required: true }
                }
              }]
            },
            comments: {
              schema: [{
                type: 'subjects',
                count: 4,
                required: true
              }]
            },
            ratings: {
              schema: [{
                type: 'critiques',
                attributes: {
                  value: { type: 'integers', required: true }
                },
                relationships: {
                  subject: {
                    schema: {
                      type: 'subjects',
                      required: true
                    }
                  }
                }
              }]
            },
            user: {
              schema: {
                type: 'users',
                required: true,
                attributes: {
                  name: { type: 'strings', required: true }
                }
              }
            }
          }
        })
      end
    end

    context 'relationships' do
      let(:relationships) do
        {
          user: {
            data: {
              type: 'users',
              id: user.id
            }
          }
        }
      end

      let(:user) { create(:user, :with_comments) }

      it 'responds with options for those relationships' do
        expect(json['schema']).to eq({
          type: 'posts',
          attributes: {
            title: { type: 'strings', required: true }
          },
          relationships: {
            attachments: {
              schema: [{
                type: 'images',
                attributes: {
                  name: { type: 'strings', required: true },
                  score: { type: 'decimals', required: true }
                }
              }, {
                type: 'videos',
                attributes: {
                  name: { type: 'strings', required: true },
                  score: { type: 'decimals', required: true }
                }
              }]
            },
            comments: {
              schema: [{
                type: 'subjects',
                count: 4,
                required: true
              }]
            },
            ratings: {
              schema: [{
                type: 'critiques',
                attributes: {
                  value: { type: 'integers', required: true }
                },
                relationships: {
                  subject: {
                    data: {
                      type: 'subjects',
                      id: user.comments.first.id
                    }
                  }
                }
              },{
                type: 'critiques',
                attributes: {
                  value: { type: 'integers', required: true }
                },
                relationships: {
                  subject: {
                    data: {
                      type: 'subjects',
                      id: user.comments.last.id
                    }
                  }
                }
              }]
            },
            user: {
              schema: {
                type: 'users',
                required: true,
                attributes: {
                  name: { type: 'strings', required: true }
                }
              }
            }
          }
        })
      end
    end
  end
end
