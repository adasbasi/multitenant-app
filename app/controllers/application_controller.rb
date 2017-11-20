class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :get_blog

private
  def get_blog

    blogs = Blog.where(subdomain: request.subdomain)

    if blogs.count > 0
      @blog = blogs.first
    elsif request.subdomain != 'www'
      redirect_to root_url(subdomain: 'www')
    end
  end
end
