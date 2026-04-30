class BlogsController < ApplicationController
  before_action :set_blog, only: %i[show]

  # def article
  # end

  # def newsletter
  # end

  def index
    @blogs = Blog.all
  end

  def latest
    @blogs = Blog.order(created_at: :desc).limit(6)
    frame_id = request.headers['Turbo-Frame'].presence
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: 'shared/turbo_frame_wrapper',
                 locals: {
                   frame_id: frame_id || 'blogs_latest',
                   partial_path: 'pages/news/blog_grid',
                   partial_locals: { blogs: @blogs }
                 }
        else
          render partial: 'pages/news/blog_grid', locals: { blogs: @blogs }
        end
      end
    end
  end

  def show
    @tags = @blog.tags
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_blog
    @blog = Blog.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def blog_params
    params.expect(blog: %i[title content])
  end
end
