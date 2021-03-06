ActivateApp::App.controllers do
  
  get '/groups/:slug/conversations' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required! unless @group.public?
    @conversations = @group.visible_conversations
    @q = params[:q] if params[:q]        
    if @q
      if @q.starts_with?('slug:')
        @conversations = @conversations.where(:slug => @q.split('slug:').last)        
      else            
        q = []
        q << {:body => /#{::Regexp.escape(@q)}/i }
        q << {:conversation_id.in => Conversation.where(:subject => /#{::Regexp.escape(@q)}/i).pluck(:id)}
        q << {:account_id.in => Account.where(:name => /#{::Regexp.escape(@q)}/i).pluck(:id)}
        conversation_posts = @group.visible_conversation_posts.or(q)
        @conversations = @conversations.where(:id.in => conversation_posts.pluck(:conversation_id))
      end
    end    
    @conversations = @conversations.order_by('pinned desc, updated_at desc').per_page(10).page(params[:page])      
    if request.xhr?
      partial :'conversations/conversations'
    else
      redirect "/groups/#{@group.slug}?#{request.query_string}"
    end
  end
    
  get '/groups/:slug/conversations/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    if @group.conversation_creation_by_admins_only and !@membership.admin?
      flash[:error] = 'Only admins can create conversations in that group'
      redirect back
    end
    @conversations = @group.conversations.build
    erb :'conversations/build'
  end  
  
  post '/groups/:slug/conversations/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    if @group.conversation_creation_by_admins_only and !@membership.admin?
      flash[:error] = 'Only admins can create conversations in that group'
      redirect back
    end    
    @conversation = @group.conversations.build(params[:conversation])
    @conversation.body ||= ''
    @conversation.account = current_account
    if @conversation.save
      @conversation_post = @conversation.visible_conversation_posts.first
      @conversation_post.send_notifications!
      redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the conversation from being created."
      erb :'conversations/build'      
    end
  end   
      
  get '/conversations/:slug' do    
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    @group = @conversation.group
    membership_required!(@group) unless @group.public?
    @membership = @group.memberships.find_by(account: current_account)
    if @conversation.hidden
      flash[:notice] = "That conversation is hidden."
      redirect "/groups/#{@group.slug}"
    else
      @title = @conversation.subject
      erb :'conversations/conversation'
    end
  end
  
  get '/conversation_post_email/:id' do
    admins_only!
    @conversation_post = ConversationPost.find(params[:id])
    erb :'emails/conversation_post', :locals => {:conversation_post => @conversation_post, :group => @conversation_post.group}, :layout => false
  end
  
  post '/conversations/:slug' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    @group = @conversation.group
    membership_required!(@group)
    @membership = @group.memberships.find_by(account: current_account)
    @conversation_post = @conversation.conversation_posts.build(params[:conversation_post])
    @conversation_post.account = current_account
    if @conversation_post.save
      @conversation_post.send_notifications!
      redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the post from being created."
      erb :'conversations/conversation'      
    end
  end
      
  get '/conversations/:slug/hide' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    group_admins_only!(@conversation.group)
    @conversation.update_attribute(:hidden, true)
    flash[:notice] = "The conversation was hidden."
    redirect "/groups/#{@conversation.group.slug}"
  end  
  
  get '/conversations/:slug/pin' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    group_admins_only!(@conversation.group)
    @conversation.update_attribute(:pinned, true)
    flash[:notice] = "The conversation was pinned."
    redirect back
  end 

  get '/conversations/:slug/unpin' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    group_admins_only!(@conversation.group)
    @conversation.update_attribute(:pinned, nil)
    flash[:notice] = "The conversation was unpinned."
    redirect back
  end 
  
  get '/conversations/:slug/hide_post/:id' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    group_admins_only!(@conversation.group)
    @conversation.visible_conversation_posts.find(params[:id]).update_attribute(:hidden, true)
    flash[:notice] = "The post was hidden."
    redirect "/conversations/#{@conversation.slug}"
  end    
  
  get '/conversations/:slug/mute' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group)
    @conversation.conversation_mutes.create(account: current_account)
    flash[:notice] = "The conversation was muted."
    redirect "/conversations/#{@conversation.slug}"
  end    
  
  get '/conversations/:slug/unmute' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group)
    @conversation.conversation_mutes.find_by(account: current_account).destroy
    flash[:notice] = "The conversation was unmuted."
    redirect "/conversations/#{@conversation.slug}"
  end      
      
  get '/conversation_posts/:id' do
    @conversation_post = ConversationPost.find(params[:id]) || not_found
    redirect "/conversations/#{@conversation_post.conversation.slug}#conversation-post-#{@conversation_post.id}"
  end  
       
  get '/conversation_posts/:id/resend' do
    @conversation_post = ConversationPost.find(params[:id])
    group_admins_only!(@conversation_post.group)
    @conversation_post.send_notifications!
    flash[:notice] = 'Emails for the post were resent.'
    redirect back
  end  
  
end