use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    http::header,
    Error,
};
use futures::future::{ready, LocalBoxFuture, Ready};
use tracing::debug;

// Default Headers Middleware
pub struct DefaultHeadersMiddleware;

impl<S, B> Transform<S, ServiceRequest> for DefaultHeadersMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = DefaultHeadersMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        debug!("Initializing default headers middleware");
        ready(Ok(DefaultHeadersMiddlewareService { service }))
    }
}

pub struct DefaultHeadersMiddlewareService<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for DefaultHeadersMiddlewareService<S>
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
        debug!("Default headers middleware processing request: {}", req.path());
        
        let fut = self.service.call(req);
        
        Box::pin(async move {
            let mut res = fut.await?;
            
            // Add security headers to all responses
            let headers = res.headers_mut();
            
            // Prevent browsers from detecting the MIME type differently than declared
            headers.insert(
                header::X_CONTENT_TYPE_OPTIONS,
                header::HeaderValue::from_static("nosniff"),
            );
            
            // Help protect against XSS attacks by restricting how browsers can interact with your content
            headers.insert(
                header::HeaderName::from_static("x-xss-protection"),
                header::HeaderValue::from_static("1; mode=block"),
            );
            
            // Control how much information the browser includes with referrers
            headers.insert(
                header::REFERRER_POLICY,
                header::HeaderValue::from_static("strict-origin-when-cross-origin"),
            );
            
            // Control how your resources can be loaded by external sites
            // This is a somewhat permissive policy, adjust based on your needs
            headers.insert(
                header::HeaderName::from_static("content-security-policy"),
                header::HeaderValue::from_static(
                    "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;"
                ),
            );
            
            // Protect against drag-and-drop style clickjacking attacks
            headers.insert(
                header::HeaderName::from_static("x-frame-options"),
                header::HeaderValue::from_static("SAMEORIGIN"),
            );
            
            Ok(res)
        })
    }
}
