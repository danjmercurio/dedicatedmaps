class MapsController < ApplicationController
  # skip_before_filter :subdomain_redirect
  skip_before_filter :verify_authenticity_token, :only => [:update]
  before_filter :handle_public_map, :only => [:show, :update]
  # before_filter :ensure_login, :only => [:show, :update, :currentlayers]
  before_action authenticate_user!


  # GET /maps/1
  def show
    unless @map
      error_404
    end

    # If the public map user is deactivated, go to a 404.
    # Deactivated private map user accounts won't get this far as they are not allowed to log in.
    unless @map.user.active
      error_404
    end

    # Only show private maps to owners and admins/supers.
    if (@map.user.privilege.name != 'public') && !(@owner_viewing || @admin_viewing)
      error_404
      return
    end

    # API key for Google Maps JS API
    # Manage this key: no-reply@dedicatedmaps.com:dmaps_email @ cloud.google.com
    # Statistics: https://console.cloud.google.com/apis/api/maps_backend/usage?project=hazel-logic-122319&duration=PT1H
    @api_key = 'AIzaSyCXWCJQoRqKt74nUWgvJBmk_naVR-TbeBg'

    # Restrict layers to those enabled by both client and user.
    @layers = @map.user.client.layers.all.order('created_at DESC') & @map.user.layers.all

    @layer_config = Hash.new
    @layers.each do |y|
      @layer_config[y.name] = {
        :type => y.category,
        :icon => y.icon,
      }
    end
    @mapState = {
        :id => @map.id,
        :zoom => @map.zoom,
        :lat => @map.lat,
        :lon => @map.lon,
        :map_type => @map.map_type
    }

    respond_to do |format|
      format.html
    end
  end


  # PUT /maps/1
  def update
    @map = Map.find(params[:id])
    @user = @map.user

    #map edit privileges
    # unless @owner_viewing || @admin_viewing
    #   render :text => err + ' 2'
    #   return
    # end
    # "#{@map.updated_at.strftime("Saved: %I:%M:%S %p %Z")}" }

    respond_to do |format|
      if @map.update_attributes({
                                    :zoom => params[:zoom],
                                    :lat => params[:lat],
                                    :lon => params[:lon],
                                    :map_type => params[:map_type]})

        response = {:status => 'OK', :timestamp => @map.updated_at}

        format.json do
          render :json => response.to_json
        end
      else
        response = {:status => 'ERROR'}
        format.json do
          render :json => response.to_json
        end
      end
    end
  end

  private 

  def handle_public_map
    @map = Map.find_by_id(params[:id].to_i)
    
    if !@map
      error_404
      return
    end
       
    # check if this is a public map viewing. If so, log user in as anonymous (public map)
    if !@loggedin_user && @map
      @session = Session.new
      @session.user_id = @map.user.id
      
      # save with validation is deprecated in rails 3
      #@session.save_with_validation(false)
      @session.save({
      	validate: false
      })


      @loggedin_user = @map.user
      @anonymous_user = true
      session[:id] = @session.id
    end

    # save button: (admin_viewing)
    #   super viewing public
    #   admin viewing public
    #   super viewing private
    #   admin viewing private
    # 
    # auto save: (ownder_viewing)
    #   user viewing private
    # 
    # nothing: (anonymous_user)
    #   public viewing public
    
    @owner_viewing = !@anonymous_user && @loggedin_user.is?(@map.user)
    @admin_viewing = !@anonymous_user && !@loggedin_user.is?(@map.user) && @loggedin_user.admin_for?(@map.user)
  end

end