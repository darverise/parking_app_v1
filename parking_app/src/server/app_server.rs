use actix_web::{App, HttpServer, middleware::Logger, web};
use crate::config::{
    logging::{init_logger, LogConfig},
    postgresql_database::{DatabaseConfig, PostgresDatabase},
};
use crate::middlewares::{
    cors_middleware::configure_cors,
    csrf_middleware::CsrfMiddleware,
    default_headers::DefaultHeadersMiddleware,
    error_handlers::ErrorHandlersMiddleware,
    identity_middleware::IdentityMiddleware,
    session_middleware::SessionMiddleware,
};
use crate::routes::route_config;

use std::io::{self, ErrorKind};
use std::net::TcpListener;
use log::{info, error, warn};

pub async fn start_server() -> std::io::Result<()> {
    // .envファイルから環境変数を読み込む
    dotenv::dotenv().ok();

    // ロギングの初期化
    let log_config = LogConfig::from_env();
    let _guard = init_logger(log_config).map_err(|e| {
        error!("ロガーの初期化に失敗しました: {}", e);
        io::Error::new(io::ErrorKind::Other, e.to_string())
    })?;

    info!("サーバーを初期化しています...");

    // データベース接続のセットアップ
    let db_config = DatabaseConfig::from_env().map_err(|e| {
        error!("データベース設定の読み込みに失敗しました: {}", e);
        io::Error::new(io::ErrorKind::Other, e.to_string())
    })?;
    
    info!("データベースに接続中...");
    let db = web::Data::new(
        PostgresDatabase::connect(&db_config)
            .await
            .map_err(|e| {
                error!("データベースへの接続に失敗しました: {}", e);
                io::Error::new(io::ErrorKind::Other, e.to_string())
            })?,
    );
    info!("データベース接続が正常に確立されました");

    // 環境変数からサーバーのアドレスとポートを設定
    let host = std::env::var("SERVER_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = std::env::var("SERVER_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .unwrap_or(8080);
    let address = format!("{}:{}", host, port);
    
    // ポートが既に使用されているか確認
    match TcpListener::bind(&address) {
        Ok(listener) => {
            // ポートが利用可能、一時リスナーを破棄
            drop(listener);
            info!("ポート{}は利用可能です", port);
        },
        Err(e) => {
            if e.kind() == ErrorKind::AddrInUse {
                error!("ポート{}は既に使用されています。.envファイルのSERVER_PORTを変更するか、このポートを使用しているプロセスを停止してください。", port);
                return Err(io::Error::new(
                    ErrorKind::AddrInUse,
                    format!("ポート{}は既に使用されています。サーバーを起動できません。", port)
                ));
            } else {
                warn!("ポートの利用可否確認中にエラーが発生しました: {}", e);
                // サーバー起動を継続
            }
        }
    }
    
    info!("サーバーを http://{} で起動します...", address);

    // サーバーの構成と起動
    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default()) // リクエストログ
            .wrap(configure_cors()) // CORS設定
            .wrap(CsrfMiddleware) // CSRF対策
            .wrap(IdentityMiddleware::new()) // アイデンティティ管理
            .wrap(SessionMiddleware::new()) // セッション管理
            .wrap(DefaultHeadersMiddleware) // デフォルトレスポンスヘッダー
            .wrap(ErrorHandlersMiddleware) // エラーハンドリング
            .app_data(db.clone()) // データベース接続プールを共有
            .configure(route_config::init_routes) // ルート登録
    })
    .workers(
        std::env::var("SERVER_WORKERS")
            .unwrap_or_else(|_| "4".to_string())
            .parse::<usize>()
            .unwrap_or(4)
    ) // ワーカースレッド数（環境変数から取得）
    .bind(&address)
    .map_err(|e| {
        error!("アドレス{}へのバインドに失敗しました: {}", address, e);
        if e.kind() == ErrorKind::AddrInUse {
            error!("ポート{}は既に使用されているようです。他のアプリケーションがこのポートを使用していないか確認するか、.envのSERVER_PORTを変更してください。", port);
        }
        e
    })?
    .run()
    .await
    .map(|_| {
        info!("サーバーが停止しました");
        ()
    })
}