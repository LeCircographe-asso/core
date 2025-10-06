module Admin
  class BlogsController < ApplicationController
    before_action :set_blog, only: %i[ show edit update destroy ]
    before_action :has_admin?

    def index
      @blogs = Blog.all
    end

    def show
      @tags=@blog.tags
    end

    def new
      @blog = Blog.new
      @tags=Tag.all
    end

    def edit
      @tags=Tag.all
    end

    def create
      @blog = Blog.new(blog_params)
      if params[:blog][:tag_ids]
        params[:blog][:tag_ids].each do |i|
          @blog.tags << Tag.find(i)
        end
      end

      if @blog.save
        redirect_to admin_blog_path(@blog), notice: "blog créé avec sucée"
      else
        render :new
      end
    end

    def update
      @blog.tags.clear
      if params[:blog][:tag_ids]
        params[:blog][:tag_ids].each do |i|
          @blog.tags << Tag.find(i)
        end
      end

      respond_to do |format|
        if @blog.update(blog_params)
          format.html { redirect_to admin_blogs_path(@blog), notice: "Blog was successfully updated." }
          format.json { render :show, status: :ok, location: @blog }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @blog.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @blog.tags.clear
      @blog.destroy!

      respond_to do |format|
        format.html { redirect_to admin_blogs_path, status: :see_other, notice: "Blog was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private
      def has_admin?
        redirect_to blogs_path, notice: "vous n'avez pas les droits" if !current_user.has_admin?
      end

      def set_blog
        @blog = Blog.find(params.expect(:id))
      end

      def blog_params
        params.expect(blog: [ :title, :content ])
      end
  end
end
