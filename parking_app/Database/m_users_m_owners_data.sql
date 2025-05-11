-- m_users テストデータ（一般ユーザー3件）

-- ユーザー1: 田中ユキ（ログイン中の通常ユーザー）
INSERT INTO m_users (
    user_id,
    login_id,
    full_name,
    phone_number,
    address,
    promotional_email_opt,
    service_email_opt,
    created_datetime,
    updated_datetime
) VALUES (
    'user_000001',
    '32a9f2f5-5d9a-4c8c-91c1-455b6bbdaa5b',
    '田中 ユキ',
    '08012345678',
    '東京都渋谷区神南1-2-3 アパート101',
    '1', -- プロモーションメールを受け取る
    '1', -- サービスメールを受け取る
    CURRENT_TIMESTAMP - INTERVAL '30 days',
    CURRENT_TIMESTAMP
);

-- ユーザー2: 鈴木タロウ（ログインしていない通常ユーザー）
INSERT INTO m_users (
    user_id,
    login_id,
    full_name,
    phone_number,
    address,
    promotional_email_opt,
    service_email_opt,
    created_datetime,
    updated_datetime
) VALUES (
    'user_000002',
    '9b8f7e6d-5c4b-3a2d-1e0f-98765432dcba',
    '鈴木 タロウ',
    '09087654321',
    '大阪府大阪市北区梅田1-1-1 マンション202',
    '0', -- プロモーションメールを受け取らない
    '1', -- サービスメールを受け取る
    CURRENT_TIMESTAMP - INTERVAL '60 days',
    CURRENT_TIMESTAMP - INTERVAL '5 days'
);

-- ユーザー3: 山田ハナコ（ログイン失敗がある通常ユーザー）
INSERT INTO m_users (
    user_id,
    login_id,
    full_name,
    phone_number,
    address,
    promotional_email_opt,
    service_email_opt,
    created_datetime,
    updated_datetime
) VALUES (
    'user_000003',
    'c7d8e9f0-1a2b-3c4d-5e6f-a1b2c3d4e5f6',
    '山田 ハナコ',
    '07098765432',
    '福岡県福岡市博多区博多駅前2-3-4',
    '1', -- プロモーションメールを受け取る
    '0', -- サービスメールを受け取らない
    CURRENT_TIMESTAMP - INTERVAL '45 days',
    CURRENT_TIMESTAMP - INTERVAL '2 hours'
);

-- m_owners テストデータ（駐車場オーナー2件）

-- オーナー1: 佐藤ケンジ（ログイン中の駐車場オーナー）
INSERT INTO m_owners (
    owner_id,
    login_id,
    registrant_type,
    full_name,
    full_name_kana,
    postal_code,
    address,
    phone_number,
    remarks,
    created_datetime,
    updated_datetime
) VALUES (
    'owner_000001',
    '54f3e2d1-c0b9-8a7d-6e5f-4f3e2d1c0b9a',
    '個人',
    '佐藤 ケンジ',
    'サトウ ケンジ',
    '123-4567',
    '愛知県名古屋市中区栄3-4-5',
    '08023456789',
    '月～金は電話対応可能',
    CURRENT_TIMESTAMP - INTERVAL '90 days',
    CURRENT_TIMESTAMP
);

-- オーナー2: 伊藤ユミコ（アカウントロック状態の駐車場オーナー）
INSERT INTO m_owners (
    owner_id,
    login_id,
    registrant_type,
    full_name,
    full_name_kana,
    postal_code,
    address,
    phone_number,
    remarks,
    created_datetime,
    updated_datetime
) VALUES (
    'owner_000002',
    'a1b2c3d4-e5f6-7a8b-9c0d-e1f2a3b4c5d6',
    '法人',
    '伊藤 ユミコ',
    'イトウ ユミコ',
    '234-5678',
    '北海道札幌市中央区北1条西5-6-7 札幌ビル8F',
    '09012345678',
    '株式会社パーキングソリューション代表',
    CURRENT_TIMESTAMP - INTERVAL '120 days',
    CURRENT_TIMESTAMP - INTERVAL '1 day'
);
