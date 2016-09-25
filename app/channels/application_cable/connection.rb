# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user_connected

    def connect
      find_verified_user
    end

    protected
    def find_verified_user
      if(self.current_user_connected = User.find_by_id(cookies.signed[:user_id]))
        self.current_user_connected
      else
        reject_unauthorized_connection
      end
    end
  end
end
