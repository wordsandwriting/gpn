class Translation
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :key, :type => String
  field :value, :type => String
    
  belongs_to :language, index: true
  
  validates_presence_of :key, :value
  validates_uniqueness_of :key, :scope => :language
    
  def self.admin_fields
    {
      :language_id => :lookup,
      :key => :text,
      :value => :text
    }
  end
  
  def summary
    "#{key}: #{value}"
  end
    
  def self.defaults
    {
      :home => 'home',
      :my_groups => 'my groups',
      :all_groups => 'all groups',
      :edit_profile => 'edit profile',
      :sign_out => 'sign out',
      :sign_in => 'sign in',
      :edit => 'edit',
      :organisation => 'organisation',
      :organisations => 'organisations',
      :position => 'position',
      :positions => 'positions',      
      :account_tagship => 'area of interest',
      :account_tagships => 'areas of interest',
      :add_another_account_tagship => 'add another area of interest',      
      :news => 'news',
      :map => 'map',
      :stats => 'stats',
      :calendar => 'calendar',
      :conversations => 'conversations',
      :welcome_to => 'welcome to',
      :affiliations => 'affiliations',
      :group => 'group',
      :groups => 'groups',
      :add_another_affiliation => 'add another affiliation',      
      :'members.one' => '1 member',
      :'members.other' => '%{count} members',
      :'members_in_this_group.one' => '1 member in this group',
      :'members_in_this_group.other' => '%{count} members in this group',
      :'people_in_your_groups.one' => '1 person in your groups',
      :'people_in_your_groups.other' => '%{count} people in your groups',
      :'mongoid.attributes.account.name' => 'Name',
      :'mongoid.attributes.account.email' => 'Email',
      :'mongoid.attributes.account.website' => 'Website',
      :'mongoid.attributes.account.time_zone' => 'Time zone',
      :'mongoid.attributes.account.language_id' => 'Language',
      :'mongoid.attributes.account.story' => 'Your story',
      :'mongoid.attributes.account.twitter_profile_url' => 'Twitter profile URL',
      :'mongoid.attributes.account.facebook_profile_url' => 'Facebook profile URL',
      :'mongoid.attributes.account.linkedin_profile_url' => 'LinkedIn profile URL',
      :'mongoid.attributes.account.picture' => 'Picture',
      :'mongoid.attributes.account.password' => 'Password',
      :'mongoid.attributes.account.location' => 'Location',
      :'mongoid.attributes.account.headline' => 'Headline',
      :'mongoid.attributes.account.antispam' => "Antispam: what's 1+1?",
      :'mongoid.attributes.account.welcome_email_body' => 'HTML. Replacements: [firstname], [group_list], [sign_in_details]',
      :'mongoid.attributes.account.account_tag_ids' => 'substances of interest',
      :'mongoid.attributes.account.unsubscribe_groups' => "Don't send me email notifications of groups listed near me",
      :'mongoid.attributes.account.unsubscribe_organisations' => "Don't send me email notifications of organisations listed near me",
      :'mongoid.attributes.account.unsubscribe_new_member' => "Don't send me email notifications of new members near me",
      :'mongoid.attributes.account.unsubscribe_message' => "Don't allow people to send me messages",            
      :'mongoid.attributes.group.landing_tab' => 'Group homepage content',
      :'mongoid.attributes.group.default_notification_level' => 'Email notification default',      
      # mongoid.errors.models.account.attributes.name[.blank, .not_found]
      :delete_account => 'delete account',
      :delete_account_instructions => "To completely remove your account, type your name into the box below and click 'Delete account'.",                
      :update_account => 'update account',
      :filter_by_name => 'filter by name',
      :filter_by_organisation => 'filter by organisation',
      :filter_by_account_tagship => 'filter by area of interest',
      :member_of => 'member of',
      :at => 'at',
      :date_joined => 'date joined',
      :name => 'name',
      :last_updated => 'last updated',
      :sort_by => 'sort by',
      :'will_paginate.previous_label' => '&#8592; Previous',
      :'will_paginate.next_label' => 'Next &#8594;',
      :'will_paginate.page_gap' => '&hellip;',
      :'will_paginate.page_entries_info.single_page.zero' => 'No %{model} found',
      :'will_paginate.page_entries_info.single_page.one' => 'Displaying 1 %{model}',
      :'will_paginate.page_entries_info.single_page.other' => 'Displaying all %{count} %{model}',
      :'will_paginate.page_entries_info.single_page_html.zero' => 'No %{model} found',
      :'will_paginate.page_entries_info.single_page_html.one' => 'Displaying <b>1</b> %{model}',
      :'will_paginate.page_entries_info.single_page_html.other' => 'Displaying <b>all&nbsp;%{count}</b> %{model}',
      :'will_paginate.page_entries_info.multi_page' => 'Displaying %{model} %{from} - %{to} of %{count} in total',
      :'will_paginate.page_entries_info.multi_page_html' => 'Displaying %{model} <b>%{from}&nbsp;-&nbsp;%{to}</b> of <b>%{count}</b> in total',
      :manage_members => 'manage members',
      :add_members => 'add members',
      :settings => 'settings',
      :emails => 'emails',
      :landing_tab => 'landing tab',
      :did_you_know => 'did you know...',
      :analytics => 'analytics',
      :email_notifications => 'email notifications',
      :join_group => 'join group',
      :leave_group => 'leave group',
      :leave_group_confirm => 'Are you sure you want to leave this group?',
      :on => 'on',
      :off => 'off',
      :you_can_also_send_a_mail_to => 'You can also send an email to',
      :fill_out_the_form_below_or_send_a_mail_to => 'Fill out the form below or send an email to',
      :last_post => 'last post',
      :new_conversation => 'new conversation',
      :group_conversations => "%{slug}'s conversations",
      :people => 'people',
      :capacity_of_at_least => 'capacity of at least',
      :accessible => 'accessible',
      :private_room_available => 'private room available',
      :serves_food => 'serves food',
      :serves_alcohol => 'serves alcohol',
      :maximum_hourly_cost => 'maximum hourly cost',
      :search => 'search',
      :new_people => 'new people',
      :view_all_people => 'view all people',
      :created => 'created',
      :attach_a_file => 'attach a file',
      :post => 'post',
      :someone_already_in_your_groups => 'Someone already in your groups',
      :your_groups => 'Your groups',
      :other_groups => 'Other groups',
      :create_a_group => 'Create a group',
      :new_group => 'New group',
      :posted_in_the_group => 'Posted in the group %{name}',
      :latest_conversations => 'Latest conversations',
      :listed => 'listed',
      :filter_by_group => 'filter by group',
      :agree => 'agree',
      :abstain => 'abstain',
      :disagree => 'disagree',
      :block => 'block',
      :currency_symbol => '£'
    }.merge(Hash[GroupType.all.map { |group_type| ["group_type.#{group_type.slug}", group_type.name] } ])
  end
      
end
