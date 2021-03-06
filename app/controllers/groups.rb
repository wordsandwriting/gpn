ActivateApp::App.controllers do
         
  get '/groups/new' do    
    ENV['GROUP_CREATION_BY_ADMINS_ONLY'] ? admins_only! : sign_in_required!
    @group = Group.new
    #    erb :'groups/build'
    erb :'groups/deprecated'
  end
  
  post '/groups/new' do
    ENV['GROUP_CREATION_BY_ADMINS_ONLY'] ? admins_only! : sign_in_required!
    @group = Group.new(params[:group])    
    @group.account = current_account
    if @group.save  
      flash[:notice] = "<strong>Great!</strong> The group was created successfully."
      @group.memberships.create! :account => current_account, :admin => true, :receive_membership_requests => true
      redirect "/groups/#{@group.slug}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the group from being saved."
      erb :'groups/build'
    end    
  end
  
  get '/groups' do      
    erb :'groups/groups'
  end
                                
  get '/groups/:slug' do    
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    redirect "/groups/#{@group.slug}/request_membership" if !@membership and @group.closed?    
    membership_required! if @group.secret?
    @account = Account.new
    @title = @group.name
    erb :'groups/group'
  end
       
  get '/groups/:slug/members' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required! unless @group.public?
    erb :'groups/members'    
  end
            
  get '/groups/:slug/request_membership' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    redirect "/groups/#{@group.slug}" if @group.public?
    (flash[:notice] = 'It is not possible to request membersip of that group' and redirect '/' if @group.secret?)
    @account = Account.new
    erb :'groups/request_membership'
  end

  post '/groups/:slug/request_membership' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    redirect back unless @group.closed?
    if current_account
      @account = current_account
    else           
      redirect back unless params[:account] and params[:account][:email]
      if !(@account = Account.find_by(email: /^#{::Regexp.escape(params[:account][:email])}$/i))
        @account = Account.new(mass_assigning(params[:account], Account))
        @account.password = Account.generate_password(8) # this password is never actually used; it's reset by process_membership_request
        if !@account.save
          flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
          halt 400, (erb :'groups/request_membership')
        end
      end
    end    
    
    if @group.memberships.find_by(account: @account)
      flash[:notice] = "You're already a member of that group!"
      redirect back
    elsif @group.membership_requests.find_by(account: @account, status: 'pending')
      flash[:notice] = "You've already requested membership of that group."
      redirect back
    else
      @membership_request = @group.membership_requests.create :account => @account, :status => 'pending', :answers => (params[:answers].each_with_index.map { |x,i| [@group.request_questions_a[i],x] } if params[:answers])
      (flash[:error] = "The membership request could not be created" and redirect back) unless @membership_request.persisted?
      
      group = @group
      
      if @group.admins_receiving_membership_requests.count > 0
        mail = Mail.new(
          :to => @group.admins_receiving_membership_requests.map(&:email),
          :from => "#{@group.slug} <#{@group.email('-noreply')}>",
          :subject => "#{@account.name} requested membership of #{@group.slug} on #{ENV['SITE_NAME']}",
          :body => erb(:'emails/membership_request', :layout => false)
        )
        mail.deliver   
      end
                      
      mail = Mail.new
      mail.to = @account.email
      mail.from = "#{@group.slug} <#{@group.email('-noreply')}>"      
      mail.subject = @group.prepare_email_subject(:membership_request_thanks)

      content = @group.prepare_email(:membership_request_thanks)
      .gsub('[firstname]',@account.name.split(' ').first)
    
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)     
      end    
      mail.html_part = html_part        
      
      mail.deliver        
      
      flash[:notice] = 'Your request was sent.'
      redirect (current_account ? '/' : '/sign_in')
    end    
  end
  
  get '/groups/:slug/join' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    redirect back if @group.closed? or @group.secret?
    if current_account
      @account = current_account
    else
      redirect "/groups/#{@group.slug}" if !params[:account]
      if !(@account = Account.find_by(email: /^#{::Regexp.escape(params[:account][:email])}$/i))   
        @new_account = true
        @account = Account.new(mass_assigning(params[:account], Account))
        @account.password = Account.generate_password(8)
        if !@account.save
          flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
          halt 400, (erb :'groups/group')
        end
      end
    end
      
    if @group.memberships.find_by(account: @account)
      flash[:error] = "#{@account.email} is already a member of this group."
      redirect back
    end
      
    @membership = @group.memberships.create :account => @account
    (flash[:error] = "The membership could not be created" and redirect back) unless @membership.persisted?
    
    if @new_account
      SignIn.create(account: @account)
      session[:account_id] = @account.id.to_s
      flash[:notice] = %Q{You joined #{@group.slug}!}
      redirect '/me/edit'      
    else
      redirect "/groups/#{@group.slug}"    
    end
  end  
  
  get '/groups/:slug/leave' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @group.memberships.find_by(:account => current_account).destroy
    redirect "/groups/#{@group.slug}"
  end  
  
  get '/groups/:slug/notification_level' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @membership =  @group.memberships.find_by(account: current_account)
    @membership.update_attribute(:notification_level, params[:level]) if Membership.notification_levels.include? params[:level]
    flash[:notice] = 'Notification options updated!'
    redirect back
  end   
            
end