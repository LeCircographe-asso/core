# frozen_string_literal: true

json.array! @users, partial: "admin/members/user", as: :user
