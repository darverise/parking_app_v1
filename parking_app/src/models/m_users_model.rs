// 論理名: ユーザー情報テーブル
// 物理名: m_users
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MUsersModel {
    // 論理名: ユーザーID
    pub user_id: String,
    // 論理名: ログインID
    // UUID
    pub login_id: String, 
    // 論理名: 氏名
    pub full_name: String,
    // 論理名: 電話番号
    pub phone_number: Option<String>,
    // 論理名: 住所
    pub address: String,
    // 論理名: プロモーションメール受信設定
    pub promotional_email_opt: String,
    // 論理名: サービスメール受信設定
    pub service_email_opt: String,
    // 論理名: 作成日時
    // TIMESTAMP
    pub created_datetime: Option<String>,
    // 論理名: 更新日時
    // TIMESTAMP
    pub updated_datetime: Option<String>,
}

impl MUsersModel {
    pub fn new(
        user_id: Option<String>,
        login_id: Option<String>,
        full_name: Option<String>,
        phone_number: Option<String>,
        address: Option<String>,
        promotional_email_opt: Option<String>,
        service_email_opt: Option<String>,
        created_datetime: Option<String>,
        updated_datetime: Option<String>,
    ) -> Self {
        Self {
            user_id: user_id.unwrap_or_default(),
            login_id: login_id.unwrap_or_default(),
            full_name: full_name.unwrap_or_default(),
            phone_number,
            address: address.unwrap_or_default(),
            promotional_email_opt: promotional_email_opt.unwrap_or_default(),
            service_email_opt: service_email_opt.unwrap_or_default(),
            created_datetime,
            updated_datetime,
        }
    }
}
