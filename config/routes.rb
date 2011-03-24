Rails.application.routes.draw do
  namespace "bigbluebutton" do
    resources :servers do
      resources :rooms
    end
  end
end
