use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    http::StatusCode,
    Error, HttpResponse, ResponseError,
};
use futures::future::{ready, LocalBoxFuture, Ready};
use serde::Serialize;
use std::fmt;
use tracing::{debug, error};

// Custom API error response format
#[derive(Serialize)]
struct ErrorResponse {
    status: String,
    message: String,
}

// Error handlers middleware
pub struct ErrorHandlersMiddleware;

impl<S, B> Transform<S, ServiceRequest> for ErrorHandlersMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = ErrorHandlersMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        debug!("Initializing error handlers middleware");
        ready(Ok(ErrorHandlersMiddlewareService { service }))
    }
}

pub struct ErrorHandlersMiddlewareService<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for ErrorHandlersMiddlewareService<S>
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
        debug!("Error handlers middleware processing request: {}", req.path());
        
        let fut = self.service.call(req);
        
        Box::pin(async move {
            // Execute the request handler
            let response = fut.await;
            
            match response {
                Ok(service_response) => {
                    // Check if the response is an error (4xx or 5xx)
                    let status = service_response.status();
                    
                    if status.is_client_error() || status.is_server_error() {
                        debug!("Response error status: {}", status);
                        
                        // You could customize error responses based on status code
                        // For example, return a custom 404 page or standard JSON error format
                        // This example just logs the error and passes it through
                    }
                    
                    Ok(service_response)
                }
                Err(err) => {
                    // Log the error
                    error!("Request error: {:?}", err);
                    Err(err)
                }
            }
        })
    }
}

// Custom error wrapper for application errors
#[derive(Debug)]
pub struct AppError {
    pub status_code: StatusCode,
    pub message: String,
}

impl AppError {
    pub fn new(status_code: StatusCode, message: impl Into<String>) -> Self {
        Self {
            status_code,
            message: message.into(),
        }
    }
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}: {}", self.status_code, self.message)
    }
}

impl ResponseError for AppError {
    fn status_code(&self) -> StatusCode {
        self.status_code
    }

    fn error_response(&self) -> HttpResponse {
        let error_response = ErrorResponse {
            status: self.status_code.to_string(),
            message: self.message.clone(),
        };
        
        HttpResponse::build(self.status_code)
            .json(error_response)
    }
}
