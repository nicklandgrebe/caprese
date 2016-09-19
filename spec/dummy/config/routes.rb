Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      caprese_resources :comments, :users
    end
  end
end
