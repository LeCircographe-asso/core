module Admin
  class BlogsController < ApplicationController

    before_action :set_blog, only: %i[ edit update destroy ]



    # GET /blogs/new
    def new
      @blog = Blog.new
      @tags=Tag.all
    end

    # GET /blogs/1/edit
    def edit
      @tags=Tag.all
    end

    # POST /blogs or /blogs.json
    def create
      p "#"*111
      p params
      p "#"*111
      p params[:tag_ids]
      p "#"*111
      @blog = Blog.new(blog_params)
      params[:blog][:tag_ids].each do |i|
        @blog.tags << Tag.find(i)
      end

      if @blog.save
        redirect_to blog_path(@blog), notice: "blog créé avec sucée"
      else
        render :new
      end

      # respond_to do |format|
      #   if @blog.save
      #     format.html { redirect_to @blog, notice: "Blog was successfully created." }
      #     format.json { render :show, status: :created, location: @blog }
      #   else
      #     format.html { render :new, status: :unprocessable_entity }
      #     format.json { render json: @blog.errors, status: :unprocessable_entity }
      #   end
      # end
    end

    # PATCH/PUT /blogs/1 or /blogs/1.json
    def update
      @blog = Blog.new(blog_params)
      params[:blog][:tag_ids].each do |i|
        @blog.tags << Tag.find(i)
      end

      respond_to do |format|
        if @blog.update(blog_params)
          format.html { redirect_to @blog, notice: "Blog was successfully updated." }
          format.json { render :show, status: :ok, location: @blog }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @blog.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /blogs/1 or /blogs/1.json
    def destroy
      @blog.destroy!

      respond_to do |format|
        format.html { redirect_to blogs_path, status: :see_other, notice: "Blog was successfully destroyed." }
        format.json { head :no_content }
      end
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
end