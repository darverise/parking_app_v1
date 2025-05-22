//! 共通CSRF Token工具类
//! src/utils/csrf_token.rs

use actix_web::HttpRequest;
use actix_web::cookie::{Cookie, SameSite};
use rand::{distr::Alphanumeric, Rng};
use std::time::{SystemTime, UNIX_EPOCH};
use tracing::{debug, warn};

/// CSRF Token工具类
pub struct CsrfTokenUtil;

impl CsrfTokenUtil {
    /// 生成一个新的CSRF Token
    /// 格式: {32位随机字符串}-{时间戳}
    pub fn generate_token() -> String {
        let rand_string: String = rand::rng()
            .sample_iter(&Alphanumeric)
            .take(32)
            .map(char::from)
            .collect();
        
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        
        let token = format!("{}-{}", rand_string, timestamp);
        debug!("Generated CSRF token: {}", &token[..8]); // 只记录前8位用于调试
        token
    }

    /// 从请求中获取CSRF Token（优先Header, 其次Cookie）
    pub fn get_token_from_request(req: &HttpRequest) -> Option<String> {
        // 1. 首先尝试从Header获取
        if let Some(header_token) = req.headers().get("X-CSRF-Token") {
            if let Ok(token_str) = header_token.to_str() {
                debug!("CSRF token found in header");
                return Some(token_str.to_string());
            }
        }
        
        // 2. 然后尝试从Cookie获取
        if let Some(cookie) = req.cookie("csrf_token") {
            debug!("CSRF token found in cookie");
            return Some(cookie.value().to_string());
        }
        
        debug!("No CSRF token found in request");
        None
    }

    /// 校验CSRF Token（Header和Cookie一致即可）
    pub fn validate_token(header_token: Option<&str>, cookie_token: Option<&str>) -> bool {
        match (header_token, cookie_token) {
            (Some(h), Some(c)) => {
                let is_valid = h == c && !h.is_empty();
                debug!("CSRF token validation result: {}", is_valid);
                if !is_valid {
                    warn!("CSRF token mismatch: header != cookie");
                }
                is_valid
            },
            (Some(_), None) => {
                warn!("CSRF token found in header but not in cookie");
                false
            },
            (None, Some(_)) => {
                warn!("CSRF token found in cookie but not in header");
                false
            },
            (None, None) => {
                warn!("No CSRF token found in either header or cookie");
                false
            }
        }
    }

    /// 从请求中验证CSRF Token
    pub fn validate_request(req: &HttpRequest) -> bool {
        let header_token = req.headers().get("X-CSRF-Token")
            .and_then(|h| h.to_str().ok());
        let cookie_token = req.cookie("csrf_token")
            .map(|c| c.value().to_string());
        debug!("Validating CSRF token: header_token = {:?}, cookie_token = {:?}", header_token, cookie_token);
        // 调用validate_token方法进行验证
        Self::validate_token(header_token, cookie_token.as_deref())
    }

    /// 创建CSRF Token的Cookie
    pub fn build_csrf_cookie(token: &str) -> Cookie<'static> {
        Cookie::build("csrf_token", token.to_string())
            .http_only(false)  // 前端需要能够读取
            .same_site(SameSite::Lax)
            .path("/")
            .max_age(actix_web::cookie::time::Duration::hours(24)) // 24小时有效
            .finish()
    }

    /// 验证Token格式是否正确
    pub fn is_valid_format(token: &str) -> bool {
        if token.is_empty() {
            return false;
        }
        
        // 检查格式: {字符串}-{数字}
        let parts: Vec<&str> = token.split('-').collect();
        if parts.len() != 2 {
            return false;
        }
        
        // 验证第一部分是32位字符串
        if parts[0].len() != 32 || !parts[0].chars().all(|c| c.is_alphanumeric()) {
            return false;
        }
        
        // 验证第二部分是时间戳
        parts[1].parse::<u64>().is_ok()
    }

    /// 检查Token是否过期（24小时）
    pub fn is_token_expired(token: &str) -> bool {
        if !Self::is_valid_format(token) {
            return true;
        }
        
        let parts: Vec<&str> = token.split('-').collect();
        if let Ok(token_timestamp) = parts[1].parse::<u64>() {
            let current_timestamp = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs();
            
            // 24小时 = 24 * 60 * 60 = 86400秒
            let expiry_duration = 86400;
            
            current_timestamp - token_timestamp > expiry_duration
        } else {
            true
        }
    }

    /// 生成带过期时间验证的Token验证
    pub fn validate_token_with_expiry(token: &str) -> bool {
        if !Self::is_valid_format(token) {
            warn!("Invalid CSRF token format");
            return false;
        }
        
        if Self::is_token_expired(token) {
            warn!("CSRF token has expired");
            return false;
        }
        
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::test::TestRequest;

    #[test]
    fn test_generate_token() {
        let token = CsrfTokenUtil::generate_token();
        assert!(!token.is_empty());
        assert!(CsrfTokenUtil::is_valid_format(&token));
    }

    #[test]
    fn test_token_format_validation() {
        let valid_token = "abcdefghijklmnopqrstuvwxyz123456-1234567890";
        assert!(CsrfTokenUtil::is_valid_format(valid_token));
        
        let invalid_tokens = vec![
            "",
            "short-123",
            "toolongabcdefghijklmnopqrstuvwxyz123456-123",
            "validlength12345678901234567890-notanumber",
            "no-dash-here",
        ];
        
        for token in invalid_tokens {
            assert!(!CsrfTokenUtil::is_valid_format(token));
        }
    }

    #[test]
    fn test_validate_token() {
        let token = "test_token";
        
        // 相同token应该通过验证
        assert!(CsrfTokenUtil::validate_token(Some(token), Some(token)));
        
        // 不同token应该失败
        assert!(!CsrfTokenUtil::validate_token(Some(token), Some("different")));
        
        // 缺少token应该失败
        assert!(!CsrfTokenUtil::validate_token(Some(token), None));
        assert!(!CsrfTokenUtil::validate_token(None, Some(token)));
        assert!(!CsrfTokenUtil::validate_token(None, None));
    }

    #[actix_web::test]
    async fn test_get_token_from_request() {
        // 测试从Header获取
        let req = TestRequest::default()
            .insert_header(("X-CSRF-Token", "test_token"))
            .to_http_request();
        
        let token = CsrfTokenUtil::get_token_from_request(&req);
        assert_eq!(token, Some("test_token".to_string()));
        
        // 测试从Cookie获取
        let req = TestRequest::default()
            .cookie(Cookie::new("csrf_token", "cookie_token"))
            .to_http_request();
        
        let token = CsrfTokenUtil::get_token_from_request(&req);
        assert_eq!(token, Some("cookie_token".to_string()));
    }
}