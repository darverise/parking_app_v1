use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error,
};
use futures::future::{ready, LocalBoxFuture, Ready};
use tracing::{debug, error, warn};
pub struct CsrfMiddleware;

impl<S, B> Transform<S, ServiceRequest> for CsrfMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = CsrfMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        debug!("Initializing CSRF middleware");
        ready(Ok(CsrfMiddlewareService { service }))
    }
}

pub struct CsrfMiddlewareService<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for CsrfMiddlewareService<S>
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
        debug!("CSRF middleware processing request: {}", req.path());

        // Skip CSRF check for GET, HEAD, OPTIONS, TRACE methods
        let method = req.method().clone();
        if method.is_safe() {
            debug!("Skipping CSRF check for safe method: {}", method);
            let fut = self.service.call(req);
            return Box::pin(async move {
                let res = fut.await?;
                Ok(res)
            });
        }

        // Verify CSRF token for other methods
        let csrf_token = req.headers().get("X-CSRF-Token").cloned();
        let cookie_token = req
            .cookie("csrf_token")
            .map(|cookie| cookie.value().to_string());

        let is_valid = match (csrf_token, cookie_token) {
            (Some(header_token), Some(cookie_value)) => {
                let header_value = header_token.to_str().unwrap_or_default();
                let is_match = header_value == cookie_value;
                if !is_match {
                    warn!("CSRF token mismatch: header={}, cookie={}", header_value, cookie_value);
                }
                is_match
            }
            _ => {
                warn!("Missing CSRF token in request");
                false
            }
        };

        if !is_valid {
            error!("CSRF validation failed for request to {}", req.path());
            // Just log for now, but you might want to return an error in production
            // return Box::pin(ready(Err(actix_web::error::ErrorForbidden("CSRF token validation failed"))));
        }

        let fut = self.service.call(req);
        Box::pin(async move {
            let res = fut.await?;
            Ok(res)
        })
    }
}
