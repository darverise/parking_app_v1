# 停车应用后端系统

## 概述

这是一个基于 Rust + Actix Web + PostgreSQL 构建的现代化停车应用后端系统，支持用户注册、登录、停车场管理、预约等功能。

## 功能特性

### ✅ 已实现功能

- 用户注册/登录系统（普通用户和停车场业主）
- JWT 双令牌认证机制
- 密码安全存储（bcrypt）
- 完整的 CORS、CSRF 防护
- 结构化日志记录
- 健康检查端点
- 统一错误处理和 API 响应格式

### 🚧 计划功能

- 停车场管理
- 停车预约系统
- 支付集成
- 推送通知
- 管理后台

## 技术架构

├── config/          # 配置管理（数据库、日志等）
├── controllers/     # HTTP 请求处理层
├── middlewares/     # 中间件（认证、CORS、安全等）
├── models/         # 数据模型定义
├── repositories/   # 数据访问层
├── routes/         # 路由配置
├── services/       # 业务逻辑层
└── utils/          # 工具函数

## 数据库设计

### 核心表结构

- `m_login` - 登录信息表
- `m_users` - 用户信息表
- `m_owners` - 业主信息表
- `t_parking_lots` - 停车场信息表
- `t_reservations` - 预约信息表

## API 端点

### 认证相关

- `POST /v1/api/auth/signin` - 用户登录
- `POST /v1/api/auth/signup` - 用户注册
- `POST /v1/api/auth/refresh` - 刷新访问令牌
- `DELETE /v1/api/auth/signout` - 用户登出

### 用户管理

- `GET /v1/api/auth/user` - 获取用户信息
- `PUT /v1/api/auth/user` - 更新用户信息
- `PUT /v1/api/auth/password` - 修改密码

### 系统

- `GET /health` - 健康检查
- `GET /health/details` - 详细健康状态

## 快速开始

### 环境要求

- Rust 1.86
- PostgreSQL 13+
- Redis（可选，用于会话存储）

### 安装和运行

1.**克隆项目**

```bash
git clone <repository-url>
cd parking_app
```

2.**设置环境变量**

```bash
cp .env.example .env
# 编辑 .env 文件，配置数据库连接等信息
```

3.**初始化数据库**

```bash
# 运行 SQL 迁移脚本
psql -h 100.64.1.10 -U postgres -d parkingappdb -f schema.sql
```

4.**启动服务**

```bash
cargo run


服务启动:
http://127.0.0.1:8080
```

## 配置说明

### 环境变量

```bash
# 数据库配置
DB_HOST=100.64.1.10
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=parking2025
DB_INITIAL_DATABASE=parkingappdb

# JWT 配置
JWT_SECRET=your_jwt_secret
JWT_REFRESH_SECRET=your_refresh_secret

# 服务器配置
SERVER_HOST=127.0.0.1
SERVER_PORT=8080
SERVER_WORKERS=4
```

## 开发指南

### 添加新的 API 端点

1. 在 `models/` 中定义请求/响应模型
2. 在 `repositories/` 中添加数据访问方法
3. 在 `services/` 中实现业务逻辑
4. 在 `controllers/` 中创建 HTTP 处理器
5. 在 `routes/` 中注册路由

### 数据库操作

- 使用 SQLx 进行类型安全的数据库操作
- 所有数据库操作都通过 Repository 层
- 支持事务处理和连接池管理

### 错误处理

- 使用统一的 `ApiError` 枚举
- 自动转换常见错误类型
- 生成标准化的错误响应

## 测试

```bash
# 单元测试
cargo test

# 集成测试
cargo test --test integration_tests


# 1. 数据库初始化
psql -h 100.64.1.10 -U postgres -d parkingappdb -f スキーマ.駐車場アプリのデータベース.sql

# 2. 环境配置（使用您提供的.env文件）
cp .env.example .env

# 3. 编译运行
cargo run --bin parking_app_server

# 4. 测试健康检查
curl http://localhost:8080/health


## 查找并停止占用端口的进程
## 1. 使用正确的lsof语法
sudo lsof -i :3000

## 2. 如果找到进程，记下PID并终止
sudo kill -9 <PID>

## 3. 如果lsof不工作，使用netstat
netstat -an | grep 3000

## 4. 最后验证端口已释放
sudo lsof -i :3000
## 应该没有输出表示端口已释放

```

## 部署

### Docker 部署

```bash
# 构建镜像
docker build -t parking-app .

# 运行容器
docker run -p 8080:8080 --env-file .env parking-app
```

### 生产环境配置

- 设置 `DEBUG_MODE=false`
- 配置适当的日志级别
- 使用强密码和安全的 JWT 密钥
- 启用 HTTPS

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 开启 Pull Request

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 联系方式

- 项目维护者：[Your Name]
- 邮箱：[your.email@example.com]
- 项目链接：[https://github.com/yourusername/parking_app]
