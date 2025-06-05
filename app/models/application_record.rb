class ApplicationRecord < ActiveRecord::Base
  require "dotiw"

  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  primary_abstract_class

  def log_color
    successful ? "#007700" : "#FF0000"
  end

  def wait_color
    "#999900"
  end
end
