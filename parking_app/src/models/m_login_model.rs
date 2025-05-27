// 論理名: ログイン情報テーブル
// 物理名: m_login
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MLoginModel {
    // 論理名: ログインID
    // UUID
    pub login_id: String,
    // 論理名: メールアドレス
    pub email: String,
    // 論理名: 電話番号
    pub phone_number: String,
    // 論理名: パスワード
    pub pass_word: String,
    // 論理名: 0：ユーザーの方・1:オーナーの方区分
    pub is_user_owner: String,
    // 論理名: ログインtoken
    pub login_token: Option<String>,
    // 論理名: ログインtoken有効期限
    // TIMESTAMP
    pub login_token_expiration: Option<String>,
    // 論理名: ログインtoken発行日時
    // TIMESTAMP
    pub login_token_issued_datetime: Option<String>,
    // 論理名: ログインtoken発行回数
    pub login_token_issued_count: i32,
    // 論理名: ログインtoken発行フラグ
    pub login_token_issued_flag: String,
    // 論理名: ログイン状態
    // 0:ログイン中・1:ログイン状態解除・2:ログイン状態解除
    pub is_login: String,
    // 論理名: ログイン日時
    // TIMESTAMP
    pub login_datetime: Option<String>,
    // 論理名: ログアウト日時
    // TIMESTAMP
    pub logout_datetime: Option<String>,
    // 論理名: ログイン失敗回数
    pub login_failed_count: i32,
    // 論理名: ログイン失敗日時
    // TIMESTAMP
    pub login_failed_datetime: Option<String>,
    // 論理名: ログイン失敗フラグ
    // 0:ログイン失敗・1:アカウントロック・2:アカウント無効
    // 3:アカウント削除・4:アカウント未登録・5:アカウント無効化
    // 6:アカウントロック解除・7:アカウント削除解除・8:アカウント無効化解除
    // 9:アカウントロック解除・10:アカウント削除解除・11:アカウント無効化解除
    pub login_failed_flag: String,
    // 論理名: ログイン失敗理由
    // 0:パスワード不正・1:アカウントロック・2:アカウント無効
    // 3:アカウント削除・4:アカウント未登録・5:アカウント無効化
    // 6:アカウントロック解除・7:アカウント削除解除・8:アカウント無効化解除
    // 9:アカウントロック解除・10:アカウント削除解除・11:アカウント無効化解除
    pub login_failed_reason: Option<String>,
    // 論理名: ログイン失敗理由詳細
    // 0:パスワード不正・1:アカウントロック・2:アカウント無効
    // 3:アカウント削除・4:アカウント未登録・5:アカウント無効化
    // 6:アカウントロック解除・7:アカウント削除解除・8:アカウント無効化解除
    // 9:アカウントロック解除・10:アカウント削除解除・11:アカウント無効化解除
    pub login_failed_reason_detail: Option<String>,
    // 論理名: ログイン失敗回数リセット日時
    // TIMESTAMP
    pub login_failed_reset_datetime: Option<String>,
    // 論理名: 作成日時
    // TIMESTAMP
    pub created_datetime: Option<String>,
    // 論理名: 更新日時
    // TIMESTAMP
    pub updated_datetime: Option<String>,
}

/// 新規ログイン作成用のモデル
impl MLoginModel {
    pub fn new(
        login_id: Option<String>,
        email: Option<String>,
        phone_number: Option<String>,
        pass_word: Option<String>,
        is_user_owner: Option<String>,
        login_token: Option<String>,
        login_token_expiration: Option<String>,
        login_token_issued_datetime: Option<String>,
        login_token_issued_count: Option<i32>,
        login_token_issued_flag: Option<String>,
        is_login: Option<String>,
        login_datetime: Option<String>,
        logout_datetime: Option<String>,
        login_failed_count: Option<i32>,
        login_failed_datetime: Option<String>,
        login_failed_flag: Option<String>,
        login_failed_reason: Option<String>,
        login_failed_reason_detail: Option<String>,
        login_failed_reset_datetime: Option<String>,
        created_datetime: Option<String>,
        updated_datetime: Option<String>,
    ) -> Self {
        Self {
            login_id: login_id.unwrap_or_default(),
            email: email.unwrap_or_default(),
            phone_number: phone_number.unwrap_or_default(),
            pass_word: pass_word.unwrap_or_default(),
            is_user_owner: is_user_owner.unwrap_or_default(),
            login_token,
            login_token_expiration,
            login_token_issued_datetime,
            login_token_issued_count: login_token_issued_count.unwrap_or(0),
            login_token_issued_flag: login_token_issued_flag.unwrap_or_default(),
            is_login: is_login.unwrap_or_default(),
            login_datetime,
            logout_datetime,
            login_failed_count: login_failed_count.unwrap_or(0),
            login_failed_datetime,
            login_failed_flag: login_failed_flag.unwrap_or_default(),
            login_failed_reason,
            login_failed_reason_detail,
            login_failed_reset_datetime,
            created_datetime,
            updated_datetime,
        }
    }
}
