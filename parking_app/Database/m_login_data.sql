-- m_login テストデータ (5件)

-- ユーザー1: 通常のユーザー (ログイン中)
INSERT INTO m_login (
    login_id, 
    email, 
    phone_number, 
    pass_word, 
    is_user_owner,
    login_token,
    login_token_expiration,
    login_token_issued_datetime,
    login_token_issued_count,
    login_token_issued_flag,
    is_login,
    login_datetime,
    created_datetime,
    updated_datetime
) VALUES (
    '32a9f2f5-5d9a-4c8c-91c1-455b6bbdaa5b',
    'tanaka.yuki@example.com',
    '08012345678',
    '$argon2id$v=19$m=65536,t=3,p=4$aFzRZ6J8KgVVXcJoYZcr9Q$xmD+vgLS3OCDcZA8R0y5XL8lOqGl9MVPJZsZS/ixB9g', -- パスワード: 'password123'
    '0', -- 通常のユーザー
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzMmE5ZjJmNS01ZDlhLTRjOGMtOTFjMS00NTViNmJiZGFhNWIiLCJyb2xlIjoiMCIsImV4cCI6MTcxNTIxOTIwMH0.AbC9kLkN3IjTH97JnJDHk4iX7f2YCzqNHQs6JQQfCXK',
    CURRENT_TIMESTAMP + INTERVAL '24 hours',
    CURRENT_TIMESTAMP,
    1,
    '1',
    '1',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP - INTERVAL '30 days',
    CURRENT_TIMESTAMP
);

-- ユーザー2: 通常のユーザー (ログインしていない)
INSERT INTO m_login (
    login_id,
    email,
    phone_number,
    pass_word,
    is_user_owner,
    is_login,
    created_datetime,
    updated_datetime
) VALUES (
    '9b8f7e6d-5c4b-3a2d-1e0f-98765432dcba',
    'suzuki.taro@example.com',
    '09087654321',
    '$argon2id$v=19$m=65536,t=3,p=4$bGwrRZ6J8KgVVXcJoYZcr9Q$3mD+vgLS3OCDcZA8R0y5XL8lOqGl9MVPJZsZS/ixA8f', -- パスワード: 'secure456'
    '0', -- 通常のユーザー
    '0',
    CURRENT_TIMESTAMP - INTERVAL '60 days',
    CURRENT_TIMESTAMP - INTERVAL '5 days'
);

-- ユーザー3: 通常のユーザー (ログイン失敗がある)
INSERT INTO m_login (
    login_id,
    email,
    phone_number,
    pass_word,
    is_user_owner,
    is_login,
    login_failed_count,
    login_failed_datetime,
    login_failed_flag,
    login_failed_reason,
    created_datetime,
    updated_datetime
) VALUES (
    'c7d8e9f0-1a2b-3c4d-5e6f-a1b2c3d4e5f6',
    'yamada.hanako@example.com',
    '07098765432',
    '$argon2id$v=19$m=65536,t=3,p=4$dXzRZ6J8KgVVXcJoYZcr9Q$5mD+vgLS3OCDcZA8R0y5XL8lOqGl9MVPJZsZS/ixC7h', -- パスワード: 'yamada789'
    '0', -- 通常のユーザー
    '0',
    2,
    CURRENT_TIMESTAMP - INTERVAL '2 hours',
    '1',
    'パスワード不一致',
    CURRENT_TIMESTAMP - INTERVAL '45 days',
    CURRENT_TIMESTAMP - INTERVAL '2 hours'
);

-- ユーザー4: 駐車場オーナー (ログイン中)
INSERT INTO m_login (
    login_id,
    email,
    phone_number,
    pass_word,
    is_user_owner,
    login_token,
    login_token_expiration,
    login_token_issued_datetime,
    login_token_issued_count,
    login_token_issued_flag,
    is_login,
    login_datetime,
    created_datetime,
    updated_datetime
) VALUES (
    '54f3e2d1-c0b9-8a7d-6e5f-4f3e2d1c0b9a',
    'sato.kenji@example.com',
    '08023456789',
    '$argon2id$v=19$m=65536,t=3,p=4$eYzRZ6J8KgVVXcJoYZcr9Q$7mD+vgLS3OCDcZA8R0y5XL8lOqGl9MVPJZsZS/ixD6g', -- パスワード: 'owner123'
    '1', -- 駐車場オーナー
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NGYzZTJkMS1jMGI5LThhN2QtNmU1Zi00ZjNlMmQxYzBiOWEiLCJyb2xlIjoiMSIsImV4cCI6MTcxNTIxOTIwMH0.XyZ9kLkN3IjTH97JnJDHk4iX7f2YCzqNHQs6JQQfBWL',
    CURRENT_TIMESTAMP + INTERVAL '24 hours',
    CURRENT_TIMESTAMP,
    5,
    '1',
    '1',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP - INTERVAL '90 days',
    CURRENT_TIMESTAMP
);

-- ユーザー5: 駐車場オーナー (アカウントロック状態)
INSERT INTO m_login (
    login_id,
    email,
    phone_number,
    pass_word,
    is_user_owner,
    is_login,
    login_failed_count,
    login_failed_datetime,
    login_failed_flag,
    login_failed_reason,
    login_failed_reason_detail,
    created_datetime,
    updated_datetime
) VALUES (
    'a1b2c3d4-e5f6-7a8b-9c0d-e1f2a3b4c5d6',
    'ito.yumiko@example.com',
    '09012345678',
    '$argon2id$v=19$m=65536,t=3,p=4$fZzRZ6J8KgVVXcJoYZcr9Q$9mD+vgLS3OCDcZA8R0y5XL8lOqGl9MVPJZsZS/ixE5f', -- パスワード: 'owner456'
    '1', -- 駐車場オーナー
    '0',
    5, -- 5回以上の失敗でロック
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    '1',
    'アカウントロック',
    '5回以上のログイン失敗によりアカウントがロックされました',
    CURRENT_TIMESTAMP - INTERVAL '120 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day'
);