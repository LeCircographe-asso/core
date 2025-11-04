module Admin
  class BlogsController < BaseController
    before_action :set_blog, only: %i[ show edit update destroy ]

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
      creator = BlogManagement::BlogCreator.new(
        title: blog_params[:title],
        content: blog_params[:content],
        tag_ids: params[:blog][:tag_ids] || []
      )

      result = creator.call

      if result.success?
        redirect_to admin_blog_path(result.blog), notice: "Blog créé avec succès"
      else
        @blog = Blog.new(blog_params)
        @tags = Tag.all
        flash.now[:alert] = result.message
        render :new, status: :unprocessable_entity
      end
    end

    def update
      updater = BlogManagement::BlogUpdater.new(
        blog_id: @blog.id,
        title: blog_params[:title],
        content: blog_params[:content],
        tag_ids: params[:blog][:tag_ids] || [],
        updated_by_id: Current.user.id
      )

      result = updater.call

      respond_to do |format|
        if result.success?
          format.html { redirect_to admin_blogs_path, notice: "Blog mis à jour avec succès" }
          format.json { render :show, status: :ok, location: @blog }
        else
          @tags = Tag.all
          format.html { render :edit, status: :unprocessable_entity, alert: result.message }
          format.json { render json: { errors: result.errors }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      deleter = BlogManagement::BlogDeleter.new(
        blog_id: @blog.id,
        deleted_by_id: Current.user.id
      )

      result = deleter.call

      respond_to do |format|
        if result.success?
          format.html { redirect_to admin_blogs_path, status: :see_other, notice: "Blog supprimé avec succès" }
          format.json { head :no_content }
        else
          format.html { redirect_to admin_blogs_path, alert: result.message }
          format.json { render json: { errors: result.errors }, status: :unprocessable_entity }
        end
      end
    end

    private
      def set_blog
        @blog = Blog.find(params.expect(:id))
      end

      def blog_params
        params.expect(blog: [ :title, :content ])
      end
  end
end
