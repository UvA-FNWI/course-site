class Auth::MailController < ApplicationController

    # Facilitates login by e-mail, using a one time code

    def self.available?
        !Auth::OpenController.available? || Settings.login_by_email
    end

    layout 'welcome'

    def login
        # e-mail address form
    end

    def create
        entry = params[:email].downcase
        parsed = Mail::Address.new entry
        if parsed.address != entry || parsed.domain.split(".").length <= 1
            redirect_to auth_mail_login_path
            return
        end
        # user has entered e-mail address
        session[:login_email] = mail = params[:email].downcase
        # generate 6-digit hex code for e-mail
        code = SecureRandom.hex(3)
        # hash it for later check
        session[:login_secret] = Digest::SHA256.hexdigest(code)
        AuthMailer.with(mail: mail, code: code).login_code.deliver_later
        redirect_to auth_mail_code_path
    end

    def code
        # secret code form
    end

    def validate
        if params[:code].size == 6
            if session[:login_secret] == Digest::SHA256.hexdigest(params[:code])
                # retrieve previously entered e-mail address
                mail = session[:login_email]
                # find existing user or create new (if possible)
                if @user = User.authenticate({ mail: mail })
                    session[:user_id] = @user.id
                    redirect_to root_url
                else
                    redirect_to root_url, alert: "The course has been restricted to not allow everyone to login. Contact your teacher if you think this is in error."
                end
            end
        else
            redirect_to root_url
        end
        # always remove entered details, whether successful or not
        reset_session
    end

end
