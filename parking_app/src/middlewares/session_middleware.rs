use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error, HttpMessage,
};
use chrono::{DateTime, Duration, Utc};
use futures::future::{ready, LocalBoxFuture, Ready};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use tracing::{debug, info};
use uuid::Uuid;

// Session data structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionData {
    pub id: String,
    pub user_id: Option<String>,
    pub created_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub data: HashMap<String, String>,
}

impl SessionData {
    pub fn new(user_id: Option<String>) -> Self {
        let now = Utc::now();
        let session_duration = Duration::hours(24); // 24 hours session duration
        
        Self {
            id: Uuid::new_v4().to_string(),
            user_id,
            created_at: now,
            expires_at: now + session_duration,
            data: HashMap::new(),
        }
    }
    
    pub fn is_expired(&self) -> bool {
        Utc::now() > self.expires_at
    }
    
    pub fn extend(&mut self) {
        let session_duration = Duration::hours(24);
        self.expires_at = Utc::now() + session_duration;
    }
}

// In-memory session store (could be replaced with Redis or another store in production)
#[derive(Debug, Clone)]
pub struct SessionStore {
    sessions: Arc<Mutex<HashMap<String, SessionData>>>,
}

impl SessionStore {
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(Mutex::new(HashMap::new())),
        }
    }
    
    pub fn get(&self, session_id: &str) -> Option<SessionData> {
        let sessions = self.sessions.lock().unwrap();
        sessions.get(session_id).cloned()
    }
    
    pub fn set(&self, session: SessionData) {
        let mut sessions = self.sessions.lock().unwrap();
        sessions.insert(session.id.clone(), session);
    }
    
    pub fn remove(&self, session_id: &str) {
        let mut sessions = self.sessions.lock().unwrap();
        sessions.remove(session_id);
    }
    
    pub fn cleanup_expired(&self) {
        let mut sessions = self.sessions.lock().unwrap();
        sessions.retain(|_, session| !session.is_expired());
    }
}

// Session middleware
pub struct SessionMiddleware {
    store: SessionStore,
}

impl SessionMiddleware {
    pub fn new() -> Self {
        debug!("Initializing session middleware");
        Self {
            store: SessionStore::new(),
        }
    }
}

impl<S, B> Transform<S, ServiceRequest> for SessionMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = SessionMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        // Clean up expired sessions periodically
        self.store.cleanup_expired();
        
        ready(Ok(SessionMiddlewareService {
            service,
            store: self.store.clone(),
        }))
    }
}

pub struct SessionMiddlewareService<S> {
    service: S,
    store: SessionStore,
}

impl<S, B> Service<ServiceRequest> for SessionMiddlewareService<S>
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
        debug!("Session middleware processing request: {}", req.path());
        
        // Extract session ID from cookie
        let session_id = req.cookie("session_id")
            .map(|cookie| cookie.value().to_string());
        
        let session = match session_id {
            Some(id) => {
                match self.store.get(&id) {
                    Some(session) => {
                        if session.is_expired() {
                            debug!("Session expired, creating new one");
                            // Create a new session if expired
                            SessionData::new(None)
                        } else {
                            debug!("Using existing session: {}", id);
                            // Extend existing session
                            let mut session = session;
                            session.extend();
                            session
                        }
                    }
                    None => {
                        debug!("Session not found, creating new one");
                        // Create a new session if not found
                        SessionData::new(None)
                    }
                }
            }
            None => {
                debug!("No session cookie, creating new session");
                // Create a new session if no cookie
                SessionData::new(None)
            }
        };
        
        // Store the session
        self.store.set(session.clone());
        
        // Add session to request extensions
        req.extensions_mut().insert(session);
        
        let store = self.store.clone();
        let fut = self.service.call(req);
        
        Box::pin(async move {
            let mut res = fut.await?;
            
            // Get the potentially modified session from response extensions
            let session_option = res.request().extensions().get::<SessionData>().cloned();
            
            if let Some(session) = session_option {
                // Update the session in the store
                store.set(session.clone());
                
                // Set the session cookie
                let cookie = format!(
                    "session_id={}; Path=/; HttpOnly; SameSite=Strict; Max-Age=86400",
                    session.id
                );
                
                res.headers_mut().append(
                    actix_web::http::header::SET_COOKIE,
                    actix_web::http::header::HeaderValue::from_str(&cookie).unwrap(),
                );
                
                info!("Session updated: {}", session.id);
            }
            
            Ok(res)
        })
    }
}
