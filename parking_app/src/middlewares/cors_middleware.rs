use actix_cors::Cors;
use actix_web::http::Method;
use tracing::debug;

// pub fn configure_cors() -> Cors {
//     debug!("Configuring CORS middleware");
    
//     // Read allowed origins from environment variables or use default
//     let allowed_origin = std::env::var("CORS_ALLOWED_ORIGIN")
//         .unwrap_or_else(|_| "http://localhost:3000".to_string());
    
//     debug!("CORS allowed origin: {}", allowed_origin);
    
//     Cors::default()
//         .allowed_origin(&allowed_origin)
//         .allowed_methods(vec![
//             Method::GET,
//             Method::POST,
//             Method::PUT,
//             Method::DELETE,
//             Method::OPTIONS,
//         ])
//         .allowed_headers(vec![
//             header::AUTHORIZATION,
//             header::CONTENT_TYPE,
//             header::ACCEPT,
//         ])
//         .expose_headers(vec![header::CONTENT_DISPOSITION])
//         .max_age(3600) // 1 hour cache for preflight requests
//         .supports_credentials()
// }


/// CORS middleware configuration for Actix Web applications
pub fn configure_cors() -> Cors {
    debug!("Configuring CORS middleware");

    // Read allowed origins from environment variables or use default
    let allowed_origins = std::env::var("CORS_ALLOWED_ORIGINS")
        .unwrap_or_else(|_| "http://localhost:3000".to_string());
    let allowed_origins: Vec<&str> = allowed_origins
        .split(',')
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect();

    let allowed_methods = std::env::var("CORS_ALLOWED_METHODS")
        .unwrap_or_else(|_| "GET,POST,PUT,DELETE,OPTIONS".to_string());
    let allowed_methods: Vec<Method> = allowed_methods
        .split(',')
        .filter_map(|m| Method::from_bytes(m.trim().as_bytes()).ok())
        .collect();

    let allowed_headers = std::env::var("CORS_ALLOWED_HEADERS")
        .unwrap_or_else(|_| "Content-Type,Authorization,Accept".to_string());
    let allowed_headers: Vec<&str> = allowed_headers
        .split(',')
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect();

    let expose_headers = std::env::var("CORS_EXPOSE_HEADERS")
        .unwrap_or_else(|_| "Content-Disposition".to_string());
    let expose_headers: Vec<&str> = expose_headers
        .split(',')
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect();

    let max_age = std::env::var("CORS_MAX_AGE")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(3600);

    let supports_credentials = std::env::var("CORS_SUPPORTS_CREDENTIALS")
        .map(|v| v == "true" || v == "1")
        .unwrap_or(true);

    debug!("CORS allowed origins: {:?}", allowed_origins);
    debug!("CORS allowed methods: {:?}", allowed_methods);
    debug!("CORS allowed headers: {:?}", allowed_headers);
    debug!("CORS expose headers: {:?}", expose_headers);
    debug!("CORS max age: {}", max_age);
    debug!("CORS supports credentials: {}", supports_credentials);

    let mut cors = Cors::default();

    for origin in allowed_origins {
        if origin == "*" {
            cors = cors.allow_any_origin();
        } else {
            cors = cors.allowed_origin(origin);
        }
    }

    if allowed_methods.iter().any(|m| m.as_str() == "*") {
        cors = cors.allow_any_method();
    } else {
        cors = cors.allowed_methods(allowed_methods.clone());
    }

    if allowed_headers.iter().any(|h| *h == "*") {
        cors = cors.allow_any_header();
    } else {
        cors = cors.allowed_headers(allowed_headers.clone());
    }

    if expose_headers.iter().any(|h| *h == "*") {
        cors = cors.expose_any_header();
    } else {
        cors = cors.expose_headers(expose_headers.clone());
    }

    cors = cors.max_age(max_age);

    if supports_credentials {
        cors = cors.supports_credentials();
    }

    cors
}
