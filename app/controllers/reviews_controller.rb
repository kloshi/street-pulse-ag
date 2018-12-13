class ReviewsController < ApplicationController
  # before_action :set_search, only: [:new, :create]

  def index

  end

  def show
    @review = Review.find(params[:id])
  end

  def new
    @search = Search.find(params[:search_id])
    @review = Review.new
    # prepare to be able to display current rating for this commune on the static map
    @reviews_in_radius = Review.near(@search.address, 1)
    @answers_within_radius = []
    @reviews_in_radius.each do |rev|
      @answers_within_radius << rev.answers.first unless rev.answers.first == nil || rev.answers.first == []
    end
    @street_average = street_average
    # =========
    @staticmap = static_map_for(@search)
    # @commune = get_commune(@search) # fetch communune based on user input address
    @zip_code = get_zip_code(@search)
    @commune = get_commune(@zip_code)
  end

  def create
    @review = Review.new(reviews_params)
    @search = Search.find(params[:search_id])
    @zip_code = get_zip_code(@search)
    @commune = get_commune(@zip_code)

    @review.commune = @commune

    @review.search = @search
    @review.address = @search.address
    @review.user = current_user
    if @review.save!
      redirect_to new_search_review_answer_path(review_id: @review.id, search_id: @review.search_id)
    else
      render :new
    end
  end

  # let's assume we don't mess with those for now
  # def edit
  # end

  # def update
  # end

  # def destroy
  # end

  private

  def static_map_for(location)
    params = {
      :center => [location.latitude, location.longitude].join(","),
      :zoom => 16,
      :size => "1000x250",
      :markers => [location.latitude, location.longitude].join(","),
      :key => ENV['GOOGLE_API_SERVER_KEY']
    }
    query_string = params.map { |k, v| "#{k}=#{v}" }.join("&")
    return "https://maps.googleapis.com/maps/api/staticmap?" + query_string
  end

  def get_commune(zip_code)
    # if commune does not exist in our DB then assign commune = N/A (first in the DB)
    commune = Commune.where(zip_code: zip_code).first
    commune = Commune.first if commune.nil?
    return commune
  end

  def get_zip_code(search)
    query = Geocoder.search([search.latitude, search.longitude]).first
    # in case geocoder (maps api) fails --> assign zip_code = 9999
    if query.nil?
      zip_code = "9999"
    else
      zip_code = query.postal_code
    end
    return zip_code
  end

  def reviews_params
    params.require(:review).permit(
      :street_review_average_rating,
      :commune_review_average_rating,
      :street_review_title,
      :street_review_content,
      :commune_review_title,
      :commune_review_content,
      :photo)
  end
end
