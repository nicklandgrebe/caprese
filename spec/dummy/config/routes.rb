Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      caprese_resources :comments, :posts, :users
    end
  end
end
