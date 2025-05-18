use actix_web::{
    dev::{forward_ready, Payload, Service, ServiceRequest, ServiceResponse, Transform},
    Error, FromRequest, HttpMessage, HttpRequest,
};
use futures::future::{ready, LocalBoxFuture, Ready};
use std::future::Future;
use std::pin::Pin;
use tracing::{debug, error, info};

use crate::middlewares::jwt::verify_jwt;

// User identity structure to store authenticated user information
#[derive(Debug, Clone)]
pub struct UserIdentity {
    pub user_id: String,
    pub user_type: String,
}

// Identity middleware
pub struct IdentityMiddleware {
    exclude_paths: Vec<String>,
}

impl IdentityMiddleware {
    pub fn new() -> Self {
        debug!("Initializing identity middleware");
        
        // Paths that don't require authentication
        let exclude_paths = vec![
            "/api/auth/login".to_string(),
            "/api/auth/register".to_string(),
            "/api/auth/refresh".to_string(),
            "/health".to_string(),
        ];
        
        Self { exclude_paths }
    }
}

impl<S, B> Transform<S, ServiceRequest> for IdentityMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = IdentityMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(IdentityMiddlewareService {
            service,
            exclude_paths: self.exclude_paths.clone(),
        }))
    }
}

pub struct IdentityMiddlewareService<S> {
    service: S,
    exclude_paths: Vec<String>,
}

impl<S, B> Service<ServiceRequest> for IdentityMiddlewareService<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let path = req.path().to_string();
        debug!("Identity middleware processing request: {}", path);
        
        // Skip authentication for excluded paths
        if self.exclude_paths.iter().any(|p| path.starts_with(p)) {
            debug!("Skipping authentication for excluded path: {}", path);
            return Box::pin(self.service.call(req));
        }
        
        // Get the authorization header
        let auth_header = req.headers().get("Authorization");
        
        match auth_header {
            Some(header_value) => {
                // Extract the Bearer token
                let auth_str = header_value.to_str().unwrap_or_default();
                if !auth_str.starts_with("Bearer ") {
                    error!("Invalid Authorization header format");
                    return Box::pin(self.service.call(req));
                }
                
                let token = &auth_str[7..]; // Skip "Bearer " prefix
                
                // Verify the JWT token
                match verify_jwt(token) {
                    Ok(claims) => {
                        info!("User authenticated: {}", claims.sub);
                        
                        // Create user identity
                        let identity = UserIdentity {
                            user_id: claims.sub,
                            user_type: claims.user_type,
                        };
                        
                        // Store the identity in request extensions
                        req.extensions_mut().insert(identity);
                    }
                    Err(e) => {
                        error!("JWT verification failed: {:?}", e);
                        // Continue without setting identity
                        // You might want to return an error here in production
                    }
                }
            }
            None => {
                debug!("No Authorization header found");
                // Continue without setting identity
                // You might want to return an error here in production
            }
        }
        
        Box::pin(self.service.call(req))
    }
}

// Extractor for getting the user identity from the request
impl FromRequest for UserIdentity {
    type Error = Error;
    type Future = Pin<Box<dyn Future<Output = Result<Self, Self::Error>>>>;

    fn from_request(req: &HttpRequest, _: &mut Payload) -> Self::Future {
        let req = req.clone();
        Box::pin(async move {
            // Get identity from request extensions
            req.extensions().get::<UserIdentity>()
                .cloned()
                .ok_or_else(|| {
                    error!("User not authenticated");
                    actix_web::error::ErrorUnauthorized("User not authenticated")
                })
        })
    }
}
