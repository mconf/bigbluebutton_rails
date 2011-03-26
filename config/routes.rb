Rails.application.routes.draw do
  namespace "bigbluebutton" do
    resources :servers do
      #scope(:path_names => { :show => 'show' }) do
        resources :rooms do
          get :join, :on => :member
        end
      #end
    end
  end
end
