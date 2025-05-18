use std::env;
use lettre::{
    transport::smtp::authentication::Credentials,
    Message, SmtpTransport, Transport,
};
use tracing::{debug, error, info};
use crate::controllers::api_error::ApiError;

/// メール送信サービス
pub struct EmailService {
    smtp_host: String,
    smtp_port: u16,
    smtp_username: String,
    smtp_password: String,
    from_email: String,
    from_name: String,
}

impl EmailService {
    /// 環境変数からEmailServiceを作成する
    pub fn from_env() -> Self {
        Self {
            smtp_host: env::var("SMTP_HOST").unwrap_or_else(|_| "smtp.gmail.com".to_string()),
            smtp_port: env::var("SMTP_PORT").unwrap_or_else(|_| "587".to_string())
                .parse().unwrap_or(587),
            smtp_username: env::var("SMTP_USERNAME").unwrap_or_default(),
            smtp_password: env::var("SMTP_PASSWORD").unwrap_or_default(),
            from_email: env::var("EMAIL_FROM_ADDRESS")
                .unwrap_or_else(|_| "noreply@parkingapp.com".to_string()),
            from_name: env::var("EMAIL_FROM_NAME")
                .unwrap_or_else(|_| "Parking App".to_string()),
        }
    }

    /// メール送信の設定が完了しているかをチェックする
    pub fn is_configured(&self) -> bool {
        !self.smtp_username.is_empty() && !self.smtp_password.is_empty()
    }

    /// 検証コードをメールで送信する
    pub async fn send_verification_code(
        &self,
        to_email: &str,
        code: &str,
    ) -> Result<(), ApiError> {
        debug!("Sending verification code to: {}", to_email);
        
        if !self.is_configured() {
            debug!("SMTP not configured, skipping actual email sending");
            // 開発環境ではコンソールにコードを表示する
            println!("Verification code for {}: {}", to_email, code);
            return Ok(());
        }
        
        let subject = "パーキングアプリ - メールアドレス認証コード";
        let body = format!(
            "こんにちは、\n\n\
            あなたのメールアドレス認証コードは次のとおりです：\n\n\
            {}\n\n\
            このコードは10分間有効です。\n\n\
            このメールにお心当たりがない場合は、無視してください。\n\n\
            よろしくお願いいたします。\n\
            パーキングアプリチーム",
            code
        );
        
        self.send_email(to_email, subject, &body).await
    }

    /// SMSコード通知用のメールを送信する
    pub async fn send_sms_code_notification(
        &self,
        to_email: &str,
        phone: &str,
        code: &str,
    ) -> Result<(), ApiError> {
        debug!("Sending SMS code notification to email: {}", to_email);
        
        if !self.is_configured() {
            debug!("SMTP not configured, skipping actual email sending");
            // 開発環境ではコンソールにコードを表示する
            println!("SMS code for {}: {}", phone, code);
            return Ok(());
        }
        
        let subject = "パーキングアプリ - SMSコード通知";
        let body = format!(
            "こんにちは、\n\n\
            電話番号 {} 宛に送信されたSMS認証コードは次のとおりです：\n\n\
            {}\n\n\
            このコードは10分間有効です。\n\n\
            このメールにお心当たりがない場合は、無視してください。\n\n\
            よろしくお願いいたします。\n\
            パーキングアプリチーム",
            phone, code
        );
        
        self.send_email(to_email, subject, &body).await
    }

    /// パスワードリセットコードを送信する
    pub async fn send_password_reset(
        &self,
        to_email: &str,
        code: &str,
    ) -> Result<(), ApiError> {
        debug!("Sending password reset code to: {}", to_email);
        
        if !self.is_configured() {
            debug!("SMTP not configured, skipping actual email sending");
            // 開発環境ではコンソールにコードを表示する
            println!("Password reset code for {}: {}", to_email, code);
            return Ok(());
        }
        
        let subject = "パーキングアプリ - パスワードリセット";
        let body = format!(
            "こんにちは、\n\n\
            パスワードリセットのリクエストを受け取りました。\n\n\
            パスワードリセット用の認証コードは次のとおりです：\n\n\
            {}\n\n\
            このコードは10分間有効です。\n\n\
            このリクエストをあなたが行っていない場合は、このメールを無視してください。\n\n\
            よろしくお願いいたします。\n\
            パーキングアプリチーム",
            code
        );
        
        self.send_email(to_email, subject, &body).await
    }

    /// 登録完了通知メールを送信する
    pub async fn send_registration_confirmation(
        &self,
        to_email: &str,
        full_name: &str,
    ) -> Result<(), ApiError> {
        debug!("Sending registration confirmation to: {}", to_email);
        
        if !self.is_configured() {
            debug!("SMTP not configured, skipping actual email sending");
            return Ok(());
        }
        
        let subject = "パーキングアプリへようこそ";
        let body = format!(
            "こんにちは{}さん、\n\n\
            パーキングアプリへのご登録ありがとうございます！\n\n\
            アカウントが正常に作成され、すぐにご利用いただけます。\n\n\
            ご不明な点がございましたら、お気軽にサポートチームまでお問い合わせください。\n\n\
            引き続きアプリをお楽しみください。\n\n\
            よろしくお願いいたします。\n\
            パーキングアプリチーム",
            full_name
        );
        
        self.send_email(to_email, subject, &body).await
    }

    /// 基本的なメール送信メソッド
    async fn send_email(
        &self, 
        to_email: &str, 
        subject: &str, 
        body: &str
    ) -> Result<(), ApiError> {
        let email = Message::builder()
            .from(format!("{} <{}>", self.from_name, self.from_email).parse().map_err(|e| {
                error!("Failed to parse from address: {}", e);
                ApiError::InternalServerError
            })?)
            .to(to_email.parse().map_err(|e| {
                error!("Failed to parse to address: {}", e);
                ApiError::ValidationError(format!("無効なメールアドレス: {}", e))
            })?)
            .subject(subject)
            .body(body.to_string())
            .map_err(|e| {
                error!("Failed to build email: {}", e);
                ApiError::InternalServerError
            })?;

        // SMTP トランスポートの設定
        let creds = Credentials::new(
            self.smtp_username.clone(),
            self.smtp_password.clone(),
        );

        // SMTPサーバーへの接続を開く
        let mailer = SmtpTransport::relay(&self.smtp_host)
            .map_err(|e| {
                error!("Failed to create SMTP transport: {}", e);
                ApiError::InternalServerError
            })?
            .credentials(creds)
            .port(self.smtp_port)
            .build();

        // メールを送信
        match mailer.send(&email) {
            Ok(_) => {
                info!("Email sent successfully to: {}", to_email);
                Ok(())
            }
            Err(e) => {
                error!("Failed to send email: {}", e);
                Err(ApiError::ServiceUnavailableError("メール送信に失敗しました".into()))
            }
        }
    }
}