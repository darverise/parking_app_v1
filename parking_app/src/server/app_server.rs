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
use crate::services::auth_signup_service::AuthSignupService;

use std::io::{self, ErrorKind};
use std::net::TcpListener;
use log::{info, error, warn};

/// アプリケーションサーバーを起動
pub async fn start_server() -> std::io::Result<()> {
    // 環境変数ファイル(.env)を読み込み
    dotenv::dotenv().ok();

    // ロギングシステムの初期化
    let log_config = LogConfig::from_env();
    let _guard = init_logger(log_config).map_err(|e| {
        error!("ロガーの初期化に失敗しました: {}", e);
        io::Error::new(io::ErrorKind::Other, e.to_string())
    })?;

    info!("アプリケーションサーバーを初期化しています...");

    // データベース設定の読み込みと接続確立
    let db_config = DatabaseConfig::from_env().map_err(|e| {
        error!("データベース設定の読み込みに失敗しました: {}", e);
        io::Error::new(io::ErrorKind::Other, e.to_string())
    })?;
    
    info!("データベースに接続中...");
    let database = PostgresDatabase::connect(&db_config)
        .await
        .map_err(|e| {
            error!("データベースへの接続に失敗しました: {}", e);
            io::Error::new(io::ErrorKind::Other, e.to_string())
        })?;
    
    let db = web::Data::new(database.clone());
    info!("データベース接続が正常に確立されました");

    // 認証サインアップサービスの初期化（同一のデータベース接続を使用）
    let auth_signup_service = web::Data::new(AuthSignupService::new(database));
    info!("認証サービスが初期化されました");

    // サーバーのホストとポート設定を環境変数から取得
    let host = std::env::var("SERVER_HOST").unwrap_or_else(|_| {
        warn!("SERVER_HOSTが設定されていません。デフォルト値 '0.0.0.0' を使用します");
        "0.0.0.0".to_string()
    });
    
    let port = std::env::var("SERVER_PORT")
        .unwrap_or_else(|_| {
            warn!("SERVER_PORTが設定されていません。デフォルト値 '3000' を使用します");
            "3000".to_string()
        })
        .parse::<u16>()
        .map_err(|e| {
            error!("SERVER_PORTの値が無効です: {}", e);
            io::Error::new(io::ErrorKind::InvalidInput, "無効なポート番号")
        })?;
    
    let address = format!("{}:{}", host, port);
    
    // ポートの利用可能性を事前確認
    match TcpListener::bind(&address) {
        Ok(listener) => {
            // ポートが利用可能、テスト用リスナーを破棄
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
                // サーバー起動を継続（一時的なネットワーク問題の可能性）
            }
        }
    }
    
    // ワーカースレッド数の設定
    let workers = std::env::var("SERVER_WORKERS")
        .unwrap_or_else(|_| {
            info!("SERVER_WORKERSが設定されていません。デフォルト値 '4' を使用します");
            "4".to_string()
        })
        .parse::<usize>()
        .unwrap_or_else(|e| {
            warn!("SERVER_WORKERSの値が無効です: {}。デフォルト値 '4' を使用します", e);
            4
        });
    
    info!("サーバーを http://{} で起動します（ワーカー数: {}）...", address, workers);

    // HTTPサーバーの構成と起動
    HttpServer::new(move || {
        App::new()
            // アプリケーションデータの登録（最優先）
            .app_data(db.clone())
            .app_data(auth_signup_service.clone())

            // ミドルウェアの適用（適用順序が重要）
            // 1. エラーハンドリング（最外層）
            .wrap(ErrorHandlersMiddleware)
            
            // 2. ロギング（リクエスト/レスポンスの記録）
            .wrap(Logger::default())
            
            // 3. デフォルトヘッダー（セキュリティヘッダー等）
            .wrap(DefaultHeadersMiddleware)
            
            // 4. CORS設定（クロスオリジンリクエスト制御）
            .wrap(configure_cors())
            
            // 5. セッション管理（認証の前提）
            .wrap(SessionMiddleware::new())
            
            // 6. アイデンティティ管理（ユーザー認証）
            .wrap(IdentityMiddleware::new())
            
            // 7. CSRF保護（認証後のセキュリティ層）
            // ログインエンドポイントを除外
            // サインアップエンドポイントを除外
            // ヘルスチェックエンドポイントを除外
            .wrap(CsrfMiddleware::new()
                .exempt("/v1/api/auth/signin")
                .exempt("/v1/api/auth/signup/user")
                .exempt("/health")
            )

            // ルート設定の適用
            .configure(route_config::init_routes)
    })
    .workers(workers)
    .bind(&address)
    .map_err(|e| {
        error!("アドレス{}へのバインドに失敗しました: {}", address, e);
        if e.kind() == ErrorKind::AddrInUse {
            error!("ポート{}は既に使用されています。他のアプリケーションがこのポートを使用していないか確認するか、.envのSERVER_PORTを変更してください。", port);
        } else if e.kind() == ErrorKind::PermissionDenied {
            error!("ポート{}へのバインドが拒否されました。管理者権限が必要な可能性があります（1024番未満のポート）。", port);
        }
        e
    })?
    .run()
    .await
    .map_err(|e| {
        error!("サーバーの実行中にエラーが発生しました: {}", e);
        e
    })?;
    
    info!("サーバーが正常に停止しました");
    Ok(())
}