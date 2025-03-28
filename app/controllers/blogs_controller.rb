class BlogsController < ApplicationController

  before_action :set_blog, only: %i[show ]

  def article
  end

  def newsletter
  end


  # GET /blogs or /blogs.json
  def index
    @blogs = Blog.all
  end

  # GET /blogs/1 or /blogs/1.json
  def show
    @tags=@blog.tags
  end

  

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blog
      @blog = Blog.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def blog_params
      params.expect(blog: [ :title, :content ])
    end
end
