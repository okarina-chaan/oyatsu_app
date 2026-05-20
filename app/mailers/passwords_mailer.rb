class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "【おやつ貯金】パスワード再設定のご案内", to: user.email_address
  end
end
