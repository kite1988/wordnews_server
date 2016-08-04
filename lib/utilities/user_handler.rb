require 'uri'

module UserHandler
  # TODO need session authentication for every request that touches data for user (e.g. learning history)

  # TODO make private, and only allow user creation if id_token is validated
  def make_user(user_name)
    newUser = User.new
    newUser.user_name = user_name
    newUser.if_translate = 1
    newUser.translate_categories = '1,2,3,4' # the default will be translate all
    newUser.save
    newUser
  end

  def make_user_with_google_check(id_token)
    google_email = email_if_google_id_valid(id_token)

    if google_email.blank?
      raise ArgumentError.new('Unable to validate google id token')
    else
      make_user google_email
    end
  end

  def email_if_google_id_valid(id_token)
    require 'net/http'

    response = Net::HTTP.get_response(URI('https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=' + id_token))
    json = JSON.parse(response.body)

    audience = ENV['google_client_id']
    alternate_audience = ENV['google_chrome_extension_client_id']

    valid = audience.strip == json['aud'] || alternate_audience.strip == json['aud']
    if valid
      json['email']
    else
      ''
    end

  end

  def UserHandler.generate_userID()
    rand(USER_ID_CREATE_MIN..USER_ID_CREATE_MAX)
  end

  def UserHandler.validate_userID(userID)
    if !userID.present?
      Rails.logger.debug "validate_userID; ID is empty string"
      return false
    end
    if !(userID =~ /^([0-9])+$/)
      Rails.logger.debug "validate_userID; ID is not a number"
      return false
    end

    userID = userID.to_i
    
    # TODO: enable this after fixing client side
    #if !userID.between?(USER_ID_CREATE_MIN, USER_ID_CREATE_MAX)
    #  Rails.logger.debug "validate_userID; ID is not in valid range"
    #  return false
    #end

    #Rails.logger.debug "validate_userID; ID[" + userID.to_s + "] is valid"
    return true
  end

  def UserHandler.create_new_user()
    counter = 0
    newUser = nil

    # Generate random userID and try to insert to User table
    # Possible that userID is duplicated. So we try 5 times.

    begin
      newUser = User.new
      newUser.if_translate = 1
      newUser.translate_categories = '1,2,3,4' # the default will be translate all
      newUser.user_name = generate_userID()

      if newUser.new_record?
        if newUser.save
          break;
        end
      end
      newUser = nil
      counter+=1
    end while counter < MAX_USER_CREATE_RETRIES

    if newUser != nil
      Rails.logger.info "create_new_user: New user created! [Name:" + newUser.user_name.to_s + "] Tries:{" + counter.to_s + "}"
    else
      Rails.logger.warn "create_new_user: ERROR: cannot create new user after " + counter.to_s + " trys"
    end

    return newUser
  end

end
