class BlogsController < ApplicationController
  def index
    @blogs = Blog.all
  end

  def show
    @posts = @blog.post
  end
end
