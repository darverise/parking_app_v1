// src/main.rs
//! 駐車場予約アプリケーション
//!
//! このプログラムは駐車場予約アプリケーションのRustバックエンドの
//! エントリーポイントです。

// libクレートからの機能をインポート
use parking_app_backend::run_app;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // アプリケーションを起動
    run_app().await
}
