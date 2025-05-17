use actix_web::web;
use crate::controllers::health_controller::{health_check, health_details};
use crate::controllers::auth_controller::{
    signin, signout, refresh_token, get_user_info, update_user, change_password
};

pub fn init_routes(cfg: &mut web::ServiceConfig) {
    // Health check endpoints
    cfg.service(health_check);
    cfg.service(health_details);

    // Auth routes with common prefix
    cfg.service(
        web::scope("/api/auth")
            .service(signin)
            .service(signout)
            .service(refresh_token)
            .service(get_user_info)
            .service(update_user)
            .service(change_password)
    );

    // 示例：带参数的 resource 路由
    cfg.route("/api/v1/resource/{id}/{name}/index.html", web::get().to(|path: web::Path<(u32, String)>| async move {
        let (id, name) = path.into_inner();
        format!("Resource: id={}, name={}", id, name)
    }));
    // 你可以根据需要添加更多 route/resource
}