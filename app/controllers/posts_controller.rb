class PostsController < ApplicationController
  def show
    @post = @blog.post.find(params[:id])
  end
end
