Rails.application.routes.draw do
  devise_for :users

  get "logs/show_log_file/:log_file_id", to: "logs#show_log_file", as: "logs_show_log_file"
  get "logs/show/:log_file_id/:log_id", to: "logs#show", as: "log_show"
  get "logs/data/:log_file_id/:log_id", to: "logs#data", as: "log_data"
  get "logs/fetch_log_messages", to: "logs#fetch_log_messages", as: "fetch_log_messages"
  get "visualizer/index"
  get "visualizer/manage_files"
  post "visualizer/process_file_uploads"
  post "visualizer/process_file/:id", to: "visualizer#process_file", as: "visualizer_process_file"
  delete "visualizer/destroy_file/:id", to: "visualizer#destroy_file", as: "visualizer_destroy_file"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "visualizer#index"
end
