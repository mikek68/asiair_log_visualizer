require 'rails_helper'

RSpec.describe "Visualizers", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/visualizer/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /upload_files" do
    it "returns http success" do
      get "/visualizer/upload_files"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/visualizer/show"
      expect(response).to have_http_status(:success)
    end
  end

end
