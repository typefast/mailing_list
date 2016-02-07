class MailingListSignupJob < ActiveJob::Base

  def perform(user)
    logger.info "signing up #{user.email}"
    subscribe(user)
  end

  def subscribe(user)
    mailchimp = Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
    list_id = Rails.application.secrets.mailchimp_list_id
    unless user.affinity.blank?
      category_title = 'AFFINITY'
      interest_name = user.affinity.upcase
      interest_id = interest_id_by_name(mailchimp, list_id, category_title, interest_name)

      result = mailchimp.lists(list_id).members.create(
        body: {
          email_address: user.email,
          status: 'subscribed',
          interests: Hash[interest_id, true]
      })
    else
      result = mailchimp.lists(list_id).members.create(
        body: {
          email_address: user.email,
          status: 'subscribed'
        })
    end
    Rails.logger.info("Subscribed #{user.email} to MailChimp") if result
  end
  
  def interest_id_by_name(mailchimp, list_id, category_title, interest_name)
    return nil if (list_id.nil? || category_title.nil? || interest_name.nil?)
    category_id = category_id_by_title(mailchimp, list_id, category_title)
    interests = mailchimp.lists(list_id).interest_categories(category_id).interests.retrieve
    
    interests['interests'].each do |interest|
      if interest['name'] == interest_name
        return interest['id']
      end
    end
    return nil
  end
  
  def category_id_by_title(mailchimp, list_id, category_title)
    return nil if (list_id.nil? || category_title.nil?)
    json_hash = mailchimp.lists(list_id).interest_categories.retrieve
    
    json_hash['categories'].each do |category|
      if category['title'] == category_title
        return category['id']
      end
    end
    return nil
  end

end