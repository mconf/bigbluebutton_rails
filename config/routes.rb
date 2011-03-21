Rails.application.routes.draw do
  namespace "bigbluebutton" do
    resources :servers
  end
end
