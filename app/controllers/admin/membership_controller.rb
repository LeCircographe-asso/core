class Admin::MembershipController < ApplicationController

  def index
    @membership = Membership.all
  end

  def show
    @membership = Memberships.find(params[:id])
  end

  def create
    @membership = Membership.create 
  end 

end
