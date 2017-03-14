Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      caprese_resources :attachments, :comments, :posts, :users
    end
  end
end
