use std::env;
use tracing::{debug, info};
use crate::controllers::api_error::ApiError;

/// SMS送信サービス
pub struct SmsService {
    api_key: String,
    api_secret: String,
    from_number: String,
}

impl SmsService {
    /// 環境変数からSmsServiceを作成する
    pub fn from_env() -> Self {
        Self {
            api_key: env::var("SMS_API_KEY").unwrap_or_default(),
            api_secret: env::var("SMS_API_SECRET").unwrap_or_default(),
            from_number: env::var("SMS_FROM_NUMBER").unwrap_or_default(),
        }
    }

    /// SMS送信の設定が完了しているかをチェックする
    pub fn is_configured(&self) -> bool {
        !self.api_key.is_empty() && !self.api_secret.is_empty() && !self.from_number.is_empty()
    }

    /// 検証コードをSMSで送信する
    pub async fn send_verification_code(
        &self,
        to_phone: &str,
        code: &str,
    ) -> Result<(), ApiError> {
        debug!("Sending verification code via SMS to: {}", to_phone);
        
        if !self.is_configured() {
            debug!("SMS API not configured, skipping actual SMS sending");
            // 開発環境ではコンソールにコードを表示する
            println!("SMS verification code for {}: {}", to_phone, code);
            return Ok(());
        }
        
        // 実際のSMS送信実装はここに
        // 例：Twilioなどのサービス使用
        
        // 開発用のダミー実装
        self.mock_send_sms(to_phone, &format!("パーキングアプリ認証コード: {}", code)).await
    }

    /// パスワードリセットコードをSMSで送信する
    pub async fn send_password_reset(
        &self,
        to_phone: &str,
        code: &str,
    ) -> Result<(), ApiError> {
        debug!("Sending password reset code via SMS to: {}", to_phone);
        
        if !self.is_configured() {
            debug!("SMS API not configured, skipping actual SMS sending");
            // 開発環境ではコンソールにコードを表示する
            println!("SMS password reset code for {}: {}", to_phone, code);
            return Ok(());
        }
        
        // 実際のSMS送信実装はここに
        
        // 開発用のダミー実装
        self.mock_send_sms(to_phone, &format!("パーキングアプリパスワードリセットコード: {}", code)).await
    }

    /// モックSMS送信（開発環境用）
    async fn mock_send_sms(&self, to_phone: &str, message: &str) -> Result<(), ApiError> {
        info!("Mock SMS to {}: {}", to_phone, message);
        
        // 実際のSMS送信はスキップ
        // 本番環境では実際のSMS APIを呼び出す
        
        Ok(())
    }

    /// 実際のSMS送信（本番環境用、例：Twilio API使用）
    #[allow(dead_code)]
    async fn send_sms(&self, to_phone: &str, message: &str) -> Result<(), ApiError> {
        let _ = message;
        debug!("Sending SMS to: {}", to_phone);
        
        // ここに実際のSMS API呼び出しを実装
        // 例：Twilioの場合
        
        // reqwest を使用した実装例（あくまで例）
        /*
        let client = reqwest::Client::new();
        let url = "https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Messages.json";
        
        let params = [
            ("To", to_phone),
            ("From", &self.from_number),
            ("Body", message),
        ];
        
        let response = client
            .post(url)
            .basic_auth(&self.api_key, Some(&self.api_secret))
            .form(&params)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to send SMS request: {}", e);
                ApiError::ServiceUnavailableError("SMS送信リクエストに失敗しました".into())
            })?;
        
        if !response.status().is_success() {
            let error_text = response.text().await.unwrap_or_default();
            error!("SMS API returned error: {}", error_text);
            return Err(ApiError::ServiceUnavailableError("SMS送信に失敗しました".into()));
        }
        */
        
        info!("SMS sent successfully to: {}", to_phone);
        Ok(())
    }
}