// 論理名: 駐車場オーナー情報テーブル
// 物理名: m_owners
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MOwnersModel {
    // 論理名: オーナーID
    pub owner_id: String,
    // 論理名: ログインID
    // UUID
    pub login_id: String,
    // 論理名: 登録者種別
    pub registrant_type: String,
    // 論理名: 氏名
    pub full_name: String,
    // 論理名: 氏名（カナ）
    pub full_name_kana: Option<String>,
    // 論理名: 郵便番号
    pub postal_code: String,
    // 論理名: 住所
    pub address: String,
    // 論理名: 電話番号
    pub phone_number: String,
    // 論理名: 備考
    pub remarks: Option<String>,
    // 論理名: 作成日時
    // TIMESTAMP
    pub created_datetime: Option<String>,
    // 論理名: 更新日時
    // TIMESTAMP
    pub updated_datetime: Option<String>,
}

impl MOwnersModel {
    pub fn new(
        owner_id: Option<String>,
        login_id: Option<String>,
        registrant_type: Option<String>,
        full_name: Option<String>,
        full_name_kana: Option<String>,
        postal_code: Option<String>,
        address: Option<String>,
        phone_number: Option<String>,
        remarks: Option<String>,
        created_datetime: Option<String>,
        updated_datetime: Option<String>,
    ) -> Self {
        Self {
            owner_id: owner_id.unwrap_or_default(),
            login_id: login_id.unwrap_or_default(),
            registrant_type: registrant_type.unwrap_or_default(),
            full_name: full_name.unwrap_or_default(),
            full_name_kana,
            postal_code: postal_code.unwrap_or_default(),
            address: address.unwrap_or_default(),
            phone_number: phone_number.unwrap_or_default(),
            remarks,
            created_datetime,
            updated_datetime,
        }
    }
}
