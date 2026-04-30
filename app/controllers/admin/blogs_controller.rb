# frozen_string_literal: true

module Admin
  class BlogsController < BaseController
    before_action :set_blog, only: %i[show edit update destroy]

    def index
      @blogs = Blog.all
    end

    def show
      @tags = @blog.tags
    end

    def new
      @blog = Blog.new
      @tags = Tag.all
    end

    def edit
      @tags = Tag.all
    end

    def create
      @blog = Blog.new(blog_params)
      @blog.tag_ids = Array(params.dig(:blog, :tag_ids)).compact_blank

      if @blog.save
        redirect_to admin_blog_path(@blog), notice: "Blog créé avec succès"
      else
        @tags = Tag.all
        flash.now[:alert] = @blog.errors.full_messages.to_sentence
        render :new, status: :unprocessable_content
      end
    end

    def update
      @blog.assign_attributes(blog_params)
      @blog.tag_ids = Array(params.dig(:blog, :tag_ids)).compact_blank

      respond_to do |format|
        if @blog.save
          format.html { redirect_to admin_blogs_path, notice: "Blog mis à jour avec succès" }
          format.json { render :show, status: :ok, location: @blog }
        else
          @tags = Tag.all
          format.html { render :edit, status: :unprocessable_content, alert: @blog.errors.full_messages.to_sentence }
          format.json { render json: { errors: @blog.errors.full_messages }, status: :unprocessable_content }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @blog.destroy
          format.html { redirect_to admin_blogs_path, status: :see_other, notice: "Blog supprimé avec succès" }
          format.json { head :no_content }
        else
          format.html { redirect_to admin_blogs_path, alert: @blog.errors.full_messages.to_sentence }
          format.json { render json: { errors: @blog.errors.full_messages }, status: :unprocessable_content }
        end
      end
    end

    private

    def set_blog
      @blog = Blog.find(params.expect(:id))
    end

    def blog_params
      params.expect(blog: %i[title content])
    end
  end
end
