// src/lib.rs
//! 駐車場予約アプリケーションのRustバックエンド
//!
//! このクレートは、駐車場予約アプリケーションのバックエンドAPIを提供します。
//! Actix-Webフレームワークを使用したRESTful APIと、PostgreSQLデータベースを
//! 使用したデータ永続化を実装しています。

pub mod config;
pub mod controllers;
pub mod middlewares;
pub mod models;
pub mod repositories;
pub mod routes;
pub mod server;
pub mod services;
pub mod utils;


/// アプリケーションを起動するメイン関数
///
/// # Example
///
/// ```
/// use parking_app_backend::run_app;
///
/// #[actix_web::main]
/// async fn main() -> std::io::Result<()> {
///     run_app().await
/// }
/// ```
pub async fn run_app() -> std::io::Result<()> {
    // Start the application server
    server::app_server::start_server().await
}
