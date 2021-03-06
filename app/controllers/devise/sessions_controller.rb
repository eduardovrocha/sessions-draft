class Devise::SessionsController < DeviseController

  prepend_before_action :require_no_authentication, only: [:new, :create]
  prepend_before_action :allow_params_authentication!, only: :create
  prepend_before_action(only: [:create]) {request.env["devise.skip_timeout"] = true}

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    yield resource if block_given?
    respond_with(resource, serialize_options(resource))
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate(auth_options)
    if self.resource
      set_flash_messages(notice: 'success sign in', kind: 'success', tittle: 'Success')
      sign_in(resource_name, resource)
      yield resource if block_given?
      redirect_to after_sign_in_path_for(resource)
    else
      set_flash_messages(notice: 'sign in failed', kind: 'error', tittle: 'Error')
      redirect_to '/users/sign_in'
    end
  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_messages(notice: 'success sign out', kind: 'success', tittle: 'Success')
    yield if block_given?
    respond_to_on_destroy
  end

  protected

  def sign_in_params
    devise_parameter_sanitizer.sanitize(:sign_in)
  end

  def serialize_options(resource)
    methods = resource_class.authentication_keys.dup
    methods = methods.keys if methods.is_a?(Hash)
    methods << :password if resource.respond_to?(:password)
    {methods: methods, only: [:password]}
  end

  def auth_options
    {scope: resource_name, recall: "#{controller_path}#new"}
  end

  private

  def respond_to_on_destroy
    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.all {head :no_content}
      format.any(*navigational_formats) {redirect_to after_sign_out_path_for(resource_name)}
    end
  end

end