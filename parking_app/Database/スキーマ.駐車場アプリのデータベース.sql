-- スキーマ: 駐車場アプリのデータベース
-- 作成日: 2025年5月4日
-- 文字コード: UTF-8
-- すべてのテーブルはUUID v4を主キーとして使用し、外部キー制約で関連付けます。

-- UUID v4生成のための拡張機能を有効化
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


DROP TRIGGER IF EXISTS trigger_set_user_id ON m_users;
DROP FUNCTION IF EXISTS set_user_id_trigger();
DROP FUNCTION IF EXISTS generate_user_id();

-- user_id生成用の関数
CREATE OR REPLACE FUNCTION generate_user_id() RETURNS VARCHAR(10) AS $$
DECLARE
    new_id VARCHAR(37);
    num INTEGER;
    max_num CONSTANT INTEGER := 999999;
    used_count BIGINT;
BEGIN
    -- 現在の使用済みIDの数を確認
    SELECT COUNT(*) INTO used_count FROM m_users WHERE user_id LIKE 'user_%';

    -- 使用済みIDが100万（max_num + 1）に達した場合、最大値を使用
    IF used_count >= max_num + 1 THEN
        RETURN 'user_999999';
    END IF;

    -- ランダムな6桁の数字を生成
    LOOP
        num := FLOOR(RANDOM() * (max_num + 1))::INTEGER;
        new_id := 'user_' || LPAD(num::TEXT, 6, '0');
        
        -- 生成したIDが未使用か確認
        IF NOT EXISTS (SELECT 1 FROM m_users WHERE user_id = new_id) THEN
            RETURN new_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- user_idを自動生成するトリガー
CREATE OR REPLACE FUNCTION set_user_id_trigger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id := generate_user_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_set_user_id
    BEFORE INSERT ON m_users
    FOR EACH ROW
    EXECUTE FUNCTION set_user_id_trigger();


-- owner_id生成用の関数
CREATE OR REPLACE FUNCTION generate_owner_id() RETURNS VARCHAR(10) AS $$
DECLARE
    new_id VARCHAR(10);
    num INTEGER;
    max_num CONSTANT INTEGER := 999999;
    used_count BIGINT;
BEGIN
    -- 現在の使用済みIDの数を確認
    SELECT COUNT(*) INTO used_count FROM m_owners WHERE owner_id LIKE 'owner_%';

    -- 使用済みIDが100万（max_num + 1）に達した場合、最大値を使用
    IF used_count >= max_num + 1 THEN
        RETURN 'owner_999999';
    END IF;

    -- ランダムな6桁の数字を生成
    LOOP
        num := FLOOR(RANDOM() * (max_num + 1))::INTEGER;
        new_id := 'owner_' || LPAD(num::TEXT, 6, '0');
        
        -- 生成したIDが未使用か確認
        IF NOT EXISTS (SELECT 1 FROM m_owners WHERE owner_id = new_id) THEN
            RETURN new_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- owner_idを自動生成するトリガー
CREATE OR REPLACE FUNCTION set_owner_id_trigger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.owner_id IS NULL THEN
        NEW.owner_id := generate_owner_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_set_owner_id
    BEFORE INSERT ON m_owners
    FOR EACH ROW
    EXECUTE FUNCTION set_owner_id_trigger();


-- parking_lot_id生成用の関数
CREATE OR REPLACE FUNCTION generate_parking_lot_id() RETURNS VARCHAR(10) AS $$
DECLARE
    new_id VARCHAR(10);
    num INTEGER;
    max_num CONSTANT INTEGER := 999999;
    used_count BIGINT;
BEGIN
    -- 現在の使用済みIDの数を確認
    SELECT COUNT(*) INTO used_count FROM t_parking_lots WHERE parking_lot_id LIKE 'P-%';

    -- 使用済みIDが100万（max_num + 1）に達した場合、最大値を使用
    IF used_count >= max_num + 1 THEN
        RETURN 'P-999999';
    END IF;

    -- ランダムな6桁の数字を生成
    LOOP
        num := FLOOR(RANDOM() * (max_num + 1))::INTEGER;
        new_id := 'P-' || LPAD(num::TEXT, 6, '0');
        
        -- 生成したIDが未使用か確認
        IF NOT EXISTS (SELECT 1 FROM t_parking_lots WHERE parking_lot_id = new_id) THEN
            RETURN new_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
-- parking_lot_idを自動生成するトリガー
CREATE OR REPLACE FUNCTION set_parking_lot_id_trigger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parking_lot_id IS NULL THEN
        NEW.parking_lot_id := generate_parking_lot_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_set_parking_lot_id
    BEFORE INSERT ON t_parking_lots
    FOR EACH ROW
    EXECUTE FUNCTION set_parking_lot_id_trigger();


-- 既存のテーブルを削除（依存関係を考慮して逆順で削除）
DROP TABLE IF EXISTS t_parking_status CASCADE;
DROP TABLE IF EXISTS t_favorites CASCADE;
DROP TABLE IF EXISTS t_usage_info CASCADE;
DROP TABLE IF EXISTS t_reservation_details CASCADE;
DROP TABLE IF EXISTS t_reservations CASCADE;
DROP TABLE IF EXISTS t_parking_google_maps CASCADE;
DROP TABLE IF EXISTS m_parking_vehicle_types CASCADE;
DROP TABLE IF EXISTS t_parking_rental_types CASCADE;
DROP TABLE IF EXISTS m_parking_features CASCADE;
DROP TABLE IF EXISTS t_parking_lots CASCADE;
DROP TABLE IF EXISTS m_profiles CASCADE;
DROP TABLE IF EXISTS m_owners CASCADE;
DROP TABLE IF EXISTS m_users CASCADE;
DROP TABLE IF EXISTS m_login CASCADE;

-- 1. ログイン情報テーブル
-- 論理名: ログイン情報テーブル
-- 物理名: m_login
CREATE TABLE m_login (
    -- 論理名: ログインID
    -- 物理名: login_id
    login_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: メールアドレス
    -- 物理名: email
    email VARCHAR(255) NOT NULL,
    -- 論理名: 電話番号
    -- 物理名: phone_number
    phone_number VARCHAR(50) NOT NULL,
    -- 論理名: パスワード
    -- 物理名: pass_word
    -- 暗号化されたパスワード
    -- 修正：passwordsをpass_wordに変更
    pass_word TEXT NOT NULL,
    -- 論理名: オーナー区分
    -- 物理名: is_user_owner
    -- 1: オーナー, 0: 一般ユーザー
    is_user_owner VARCHAR(1) NOT NULL,
    -- 論理名: ログインtoken
    -- 物理名: login_token
    login_token TEXT,
    -- 論理名: ログインtoken有効期限
    -- 物理名: login_token_expiration
    login_token_expiration TIMESTAMP WITH TIME ZONE,
    -- 論理名: ログインtoken発行日時
    -- 物理名: login_token_issued_datetime
    login_token_issued_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: ログインtoken発行回数
    -- 物理名: login_token_issued_count
    login_token_issued_count INTEGER NOT NULL DEFAULT 0,
    -- 論理名: ログインtoken発行フラグ
    -- 物理名: login_token_issued_flag
    -- 1: 発行済み, 0: 未発行
    login_token_issued_flag VARCHAR(1) NOT NULL,
    -- 論理名: ログイン状態
    -- 物理名: is_login
    -- 1: ログイン中, 0: ログインしていない
    is_login VARCHAR(1) NOT NULL,
    -- 論理名: ログイン日時
    -- 物理名: login_datetime
    login_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: ログアウト日時
    -- 物理名: logout_datetime
    logout_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: ログイン失敗回数
    -- 物理名: login_failed_count
    login_failed_count INTEGER NOT NULL DEFAULT 0,
    -- 論理名: ログイン失敗日時
    -- 物理名: login_failed_datetime
    login_failed_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: ログイン失敗フラグ
    -- 物理名: login_failed_flag
    -- 1: ログイン失敗, 0: ログイン成功
    login_failed_flag VARCHAR(1) NOT NULL,
    -- 論理名: ログイン失敗理由
    -- 物理名: login_failed_reason
    -- 例: パスワード不一致, アカウントロック
    login_failed_reason VARCHAR(255),
    -- 論理名: ログイン失敗理由詳細
    -- 物理名: login_failed_reason_detail
    -- 例: パスワード不一致, アカウントロック
    login_failed_reason_detail TEXT,
    -- 論理名: ログイン失敗回数リセット日時
    -- 物理名: login_failed_reset_datetime
    login_failed_reset_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_is_user_owner CHECK (is_user_owner IN ('0', '1')),
    CONSTRAINT unique_m_login_email UNIQUE (email),
    CONSTRAINT unique_m_login_phone_number UNIQUE (phone_number),
    CONSTRAINT pk_m_login PRIMARY KEY (login_id)
);
-- テーブルコメント
COMMENT ON TABLE m_login IS 'ユーザーのログイン情報（メール、電話番号、パスワード、オーナー区分）を格納するテーブル。';
-- カラムコメント
COMMENT ON COLUMN m_login.login_id IS 'ログインの一意制約識別子（UUID v4）';
COMMENT ON COLUMN m_login.email IS 'ユーザーのメールアドレス（一意制約）';
COMMENT ON COLUMN m_login.phone_number IS 'ユーザーの電話番号（一意制約）';
-- 修正：passwordsをpass_wordに変更
COMMENT ON COLUMN m_login.pass_word IS '暗号化されたパスワード';
COMMENT ON COLUMN m_login.is_user_owner IS 'オーナー区分（1: オーナー, 0: 一般ユーザー）';
COMMENT ON COLUMN m_login.login_token IS 'ログインtoken';
COMMENT ON COLUMN m_login.login_token_expiration IS 'ログインtokenの有効期限';
COMMENT ON COLUMN m_login.login_token_issued_datetime IS 'ログインtokenの発行日時';
COMMENT ON COLUMN m_login.login_token_issued_count IS 'ログインtokenの発行回数';
COMMENT ON COLUMN m_login.login_token_issued_flag IS 'ログインtokenの発行フラグ（1: 発行済み, 0: 未発行）';
COMMENT ON COLUMN m_login.is_login IS 'ログイン状態（1: ログイン中, 0: ログインしていない）';
COMMENT ON COLUMN m_login.login_datetime IS 'ログイン日時';
COMMENT ON COLUMN m_login.logout_datetime IS 'ログアウト日時';
COMMENT ON COLUMN m_login.login_failed_count IS 'ログイン失敗回数';
COMMENT ON COLUMN m_login.login_failed_datetime IS 'ログイン失敗日時';
COMMENT ON COLUMN m_login.login_failed_flag IS 'ログイン失敗フラグ（1: ログイン失敗, 0: ログイン成功）';
COMMENT ON COLUMN m_login.login_failed_reason IS 'ログイン失敗理由（例: パスワード不一致, アカウントロック）';
COMMENT ON COLUMN m_login.login_failed_reason_detail IS 'ログイン失敗理由詳細（例: パスワード不一致, アカウントロック）';
COMMENT ON COLUMN m_login.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN m_login.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_m_login_email ON m_login(email);
CREATE INDEX idx_m_login_phone_number ON m_login(phone_number);

-- 2. ユーザー情報テーブル
-- 論理名: ユーザー情報テーブル
-- 物理名: m_users
CREATE TABLE m_users (
    -- 論理名: ユーザーID
    -- 物理名: user_id
    user_id VARCHAR(37) NOT NULL DEFAULT generate_user_id(),
    -- 論理名: ログインID
    -- 物理名: login_id
    -- 修正：login_idを追加
    login_id UUID NOT NULL,
    -- 論理名: 氏名
    -- 物理名: full_name
    full_name VARCHAR(100) NOT NULL,
    -- 論理名: 生年月日
    -- 物理名: birthday
    birthday DATE,
    -- 論理名: 性別
    -- 物理名: gender
    gender VARCHAR(10),
    -- 論理名: 電話番号
    -- 物理名: phone_number
    phone_number VARCHAR(50) NOT NULL,
    -- 論理名: 住所
    -- 物理名: address
    address TEXT NOT NULL,
    -- 論理名: プロモーションメール受信設定
    -- 物理名: promotional_email_opt
    -- 1: 受け取る, 0: 受け取らない
    promotional_email_opt VARCHAR(1) NOT NULL DEFAULT '0',
    -- 論理名: サービスメール受信設定
    -- 物理名: service_email_opt
    -- 1: 受け取る, 0: 受け取らない
    service_email_opt VARCHAR(1) NOT NULL DEFAULT '1',
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_promotional_email_opt CHECK (promotional_email_opt IN ('0', '1')),
    -- CONSTRAINT check_service_email_opt CHECK (service_email_opt IN ('0', '1')),
    -- CONSTRAINT check_user_not_owner CHECK (EXISTS (SELECT 1 FROM m_login WHERE m_login.login_id = m_users.login_id AND m_login.is_user_owner = '0')),
    -- CONSTRAINT fk_m_users_login_id FOREIGN KEY (login_id) REFERENCES m_login(login_id) ON DELETE CASCADE,
    CONSTRAINT unique_m_users_phone_number UNIQUE (phone_number),
    CONSTRAINT pk_m_users PRIMARY KEY (user_id)
);
-- テーブルコメント
COMMENT ON TABLE m_users IS '一般ユーザーの基本情報（氏名、電話番号、住所、メール通知設定）を格納するテーブル。';
-- カラムコメント
COMMENT ON COLUMN m_users.user_id IS 'ユーザーの一意識別子（形式: user_XXXXXX, XXXXXXは6桁のランダムかつ一意な数字、例: user_000007）';
-- 修正：login_idを追加
COMMENT ON COLUMN m_users.login_id IS '関連するログインID';
COMMENT ON COLUMN m_users.full_name IS 'ユーザーの氏名';
COMMENT ON COLUMN m_users.phone_number IS 'ユーザーの電話番号（一意、可NULL）';
COMMENT ON COLUMN m_users.address IS 'ユーザーの住所';
COMMENT ON COLUMN m_users.promotional_email_opt IS 'プロモーションメールの受信設定（1: 受け取る, 0: 受け取らない）';
COMMENT ON COLUMN m_users.service_email_opt IS 'サービス関連メールの受信設定（1: 受け取る, 0: 受け取らない）';
COMMENT ON COLUMN m_users.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN m_users.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_m_users_login_id ON m_users(login_id);
CREATE INDEX idx_m_users_phone_number ON m_users(phone_number);
-- 修正：user_idのデフォルト値を設定
ALTER TABLE m_users 
ALTER COLUMN user_id SET DEFAULT generate_user_id();

-- 3. オーナー情報テーブル
-- 論理名: 駐車場オーナー情報テーブル
-- 物理名: m_owners
CREATE TABLE m_owners (
    -- 論理名: オーナーID
    -- 物理名: owner_id
    owner_id VARCHAR(37) NOT NULL DEFAULT generate_owner_id(),
    -- 論理名: ログインID
    -- 物理名: login_id
    login_id UUID NOT NULL,
    -- 論理名: 登録者種別
    -- 物理名: registrant_type
    -- 例: 個人, 法人
    registrant_type VARCHAR(20) NOT NULL,
    -- 論理名: 氏名
    -- 物理名: full_name
    full_name VARCHAR(100) NOT NULL,
    -- 論理名: 氏名（カナ）
    -- 物理名: full_name_kana
    full_name_kana VARCHAR(100),
    -- 論理名: 生年月日
    -- 物理名: birthday
    birthday DATE,
    -- 論理名: 性別
    -- 物理名: gender
    gender VARCHAR(10),
    -- 論理名: 郵便番号
    -- 物理名: postal_code
    -- 例: 123-4567
    postal_code VARCHAR(20) NOT NULL,
    -- 論理名: 住所
    -- 物理名: address
    address TEXT NOT NULL,
    -- 論理名: 電話番号
    -- 物理名: phone_number
    phone_number VARCHAR(50) NOT NULL,
    -- 論理名: 備考
    -- 物理名: remarks
    remarks TEXT,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_registrant_type CHECK (registrant_type IN ('個人', '法人')),
    -- CONSTRAINT check_postal_code CHECK (postal_code ~ '^\d{3}-\d{4}$'),
    -- CONSTRAINT check_owner_is_owner CHECK (EXISTS (SELECT 1 FROM m_login WHERE m_login.login_id = m_owners.login_id AND m_login.is_user_owner = '1')),
    -- CONSTRAINT fk_m_owners_login_id FOREIGN KEY (login_id) REFERENCES m_login(login_id) ON DELETE CASCADE,
    CONSTRAINT unique_m_owners_phone_number UNIQUE (phone_number),
    CONSTRAINT pk_m_owners PRIMARY KEY (owner_id)
);
-- テーブルコメント
COMMENT ON TABLE m_owners IS '駐車場オーナーの基本情報（登録者種別、氏名、住所、電話番号など）を格納するテーブル。';
-- カラムコメント
COMMENT ON COLUMN m_owners.owner_id IS 'オーナーの一意識別子（形式: owner_XXXXXX, XXXXXXは6桁のランダムかつ一意な数字、例: owner_000007）';
COMMENT ON COLUMN m_owners.login_id IS '関連するログインID';
COMMENT ON COLUMN m_owners.registrant_type IS '登録者種別（個人または法人）';
COMMENT ON COLUMN m_owners.full_name IS 'オーナーの氏名';
COMMENT ON COLUMN m_owners.full_name_kana IS 'オーナーの氏名（カタカナ、可NULL）';
-- 修正：postalleg_codeをpostal_codeに修正
COMMENT ON COLUMN m_owners.postal_code IS 'オーナーの郵便番号（例: 123-4567）';
COMMENT ON COLUMN m_owners.address IS 'オーナーの住所';
COMMENT ON COLUMN m_owners.phone_number IS 'オーナーの電話番号（一意）';
COMMENT ON COLUMN m_owners.remarks IS 'オーナーに関する備考';
COMMENT ON COLUMN m_owners.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN m_owners.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_m_owners_login_id ON m_owners(login_id);
CREATE INDEX idx_m_owners_phone_number ON m_owners(phone_number);


-- 4. プロフィールテーブル
-- 論理名: プロフィールテーブル
-- 物理名: m_profiles
CREATE TABLE m_profiles (
    -- 論理名: プロフィールID
    -- 物理名: profile_id
    profile_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: ユーザーID
    -- 物理名: user_id
    user_id VARCHAR(37),
    -- 論理名: オーナーID
    -- 物理名: owner_id
    owner_id VARCHAR(37),
    -- 論理名: 写真ファイルパス
    -- 物理名: photo_path
    photo_path TEXT NOT NULL,
    -- 論理名: 写真説明
    -- 物理名: photo_description
    photo_description TEXT,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_user_or_owner CHECK (user_id IS NOT NULL OR owner_id IS NOT NULL),
    -- CONSTRAINT check_not_both_user_and_owner CHECK (NOT (user_id IS NOT NULL AND owner_id IS NOT NULL)),
    -- CONSTRAINT fk_m_profiles_user_id FOREIGN KEY (user_id) REFERENCES m_users(user_id) ON DELETE CASCADE,
    -- CONSTRAINT fk_m_profiles_owner_id FOREIGN KEY (owner_id) REFERENCES m_owners(owner_id) ON DELETE CASCADE,
    CONSTRAINT pk_m_profiles PRIMARY KEY (profile_id)
);
-- テーブルコメント
COMMENT ON TABLE m_profiles IS 'ユーザーまたはオーナーのプロフィール情報（写真ファイルパス、写真説明など）を格納するテーブル。';
-- カラムコメント
COMMENT ON COLUMN m_profiles.profile_id IS 'プロフィールの一意識別子（UUID v4）';
COMMENT ON COLUMN m_profiles.user_id IS '関連するユーザーID（形式: user_XXXXXX, 可NULL）';
COMMENT ON COLUMN m_profiles.owner_id IS '関連するオーナーID（形式: owner_XXXXXX, 可NULL）';
COMMENT ON COLUMN m_profiles.photo_path IS '写真のファイルパス';
COMMENT ON COLUMN m_profiles.photo_description IS '写真の説明（可NULL）';
COMMENT ON COLUMN m_profiles.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN m_profiles.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_m_profiles_user_id ON m_profiles(user_id);
CREATE INDEX idx_m_profiles_owner_id ON m_profiles(owner_id);

-- 1. 駐車場基本情報テーブル
-- 論理名: 駐車場基本情報テーブル
-- 物理名: t_parking_lots
CREATE TABLE t_parking_lots (
    -- 論理名: 駐車場ID
    -- 物理名: parking_lot_id
    parking_lot_id VARCHAR(37) NOT NULL,
    -- 論理名: オーナーID
    -- 物理名: owner_id
    owner_id VARCHAR(37) NOT NULL,
    -- 論理名: 駐車場名
    -- 物理名: parking_lot_name
    parking_lot_name VARCHAR(100) NOT NULL,
    -- 論理名: 郵便番号
    -- 物理名: postal_code
    postal_code VARCHAR(20) NOT NULL,
    -- 論理名: 都道府県
    -- 物理名: prefecture
    prefecture VARCHAR(10) NOT NULL,
    -- 論理名: 市区町村
    -- 物理名: city
    city VARCHAR(50) NOT NULL,
    -- 論理名: 番地・建物名
    -- 物理名: address_detail
    address_detail TEXT NOT NULL,
    -- 論理名: 電話番号
    -- 物理名: phone_number
    phone_number VARCHAR(50) NOT NULL,
    -- 論理名: 収容台数
    -- 物理名: capacity
    capacity INTEGER NOT NULL,
    -- 論理名: 収容空き台数
    -- 物理名: available_capacity
    available_capacity INTEGER,
    -- 論理名: 貸出タイプ
    -- 物理名: rental_type
    rental_type VARCHAR(20),
    -- 論理名: 料金
    -- 物理名: charge
    charge TEXT NOT NULL,
    -- 論理名: 特徴概要
    -- 物理名: features_tip
    features_tip TEXT,
    -- 論理名: 長さ制限
    -- 物理名: length_limit
    length_limit INTEGER,
    -- 論理名: 幅制限
    -- 物理名: width_limit
    width_limit INTEGER,
    -- 論理名: 高さ制限
    -- 物理名: height_limit
    height_limit INTEGER,
    -- 論理名: 重量制限
    -- 物理名: weight_limit
    weight_limit INTEGER,
    -- 論理名: 車高制限
    -- 物理名: car_height_limit
    car_height_limit VARCHAR(20),
    -- 論理名: タイヤ幅制限
    -- 物理名: tire_width_limit
    tire_width_limit VARCHAR(20),
    -- 論理名: 車種
    -- 物理名: vehicle_type
    vehicle_type VARCHAR(20),
    -- 論理名: 最近車站
    -- 物理名: nearest_station
    nearest_station VARCHAR(100),
    -- 論理名: 状態
    -- 物理名: status
    status VARCHAR(20) NOT NULL,
    -- 論理名: 利用開始日
    -- 物理名: start_date
    start_date DATE NOT NULL,
    -- 論理名: 利用停止日
    -- 物理名: end_date
    end_date DATE,
    -- 論理名: 利用停止開始日時
    -- 物理名: end_start_datetime
    end_start_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: 利用停止終了日時
    -- 物理名: end_end_datetime
    end_end_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: 停止理由
    -- 物理名: end_reason
    end_reason VARCHAR(50),
    -- 論理名: 停止理由詳細
    -- 物理名: end_reason_detail
    end_reason_detail TEXT,
    -- 論理名: 注意事項
    -- 物理名: notes
    notes TEXT,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_postal_code CHECK (postal_code ~ '^\d{3}-\d{4}$'),
    -- CONSTRAINT check_capacity CHECK (capacity > 0),
    -- CONSTRAINT check_available_capacity CHECK (available_capacity IS NULL OR available_capacity >= 0),
    -- CONSTRAINT check_rental_type CHECK (rental_type IS NULL OR rental_type IN ('時間単位', '日間単位')),
    -- CONSTRAINT check_length_limit CHECK (length_limit IS NULL OR length_limit > 0),
    -- CONSTRAINT check_width_limit CHECK (width_limit IS NULL OR width_limit > 0),
    -- CONSTRAINT check_height_limit CHECK (height_limit IS NULL OR height_limit > 0),
    -- CONSTRAINT check_weight_limit CHECK (weight_limit IS NULL OR weight_limit > 0),
    -- CONSTRAINT check_car_height_limit CHECK (car_height_limit IS NULL OR car_height_limit IN ('制限なし', '150cm以下', '180cm以下', '200cm以下')),
    -- CONSTRAINT check_tire_width_limit CHECK (tire_width_limit IS NULL OR tire_width_limit IN ('制限なし')),
    -- CONSTRAINT check_vehicle_type CHECK (vehicle_type IS NULL OR vehicle_type IN ('オートバイ', '軽自動車', 'ワンボックスカー', '中型車')),
    -- CONSTRAINT check_status CHECK (status IN ('アクティブ', '停止中')),
    -- CONSTRAINT check_end_reason CHECK (end_reason IS NULL OR end_reason IN ('メンテナンス・維持', 'その他')),
    -- CONSTRAINT check_end_date_reason CHECK (
    --     (end_date IS NULL AND end_reason IS NULL AND end_reason_detail IS NULL) OR
    --     (end_date IS NOT NULL AND end_reason IS NOT NULL)
    -- ),
    -- CONSTRAINT check_end_datetime_reason CHECK (
    --     (end_start_datetime IS NULL AND end_end_datetime IS NULL AND end_reason IS NULL AND end_reason_detail IS NULL) OR
    --     (end_start_datetime IS NOT NULL AND end_end_datetime IS NOT NULL AND end_reason IS NOT NULL)
    -- ),
    -- CONSTRAINT check_end_datetime_order CHECK (
    --     end_start_datetime IS NULL OR end_end_datetime IS NULL OR end_start_datetime <= end_end_datetime
    -- ),
    -- CONSTRAINT check_end_reason_detail CHECK (
    --     (end_reason = 'その他' AND end_reason_detail IS NOT NULL) OR
    --     (end_reason != 'その他' OR end_reason IS NULL)
    -- ),
    -- CONSTRAINT fk_t_parking_lots_owner_id FOREIGN KEY (owner_id) REFERENCES m_owners(owner_id) ON DELETE CASCADE,
    CONSTRAINT unique_t_parking_lots_phone_number UNIQUE (phone_number),
    CONSTRAINT pk_t_parking_lots PRIMARY KEY (parking_lot_id)
);
-- テーブルコメント
COMMENT ON TABLE t_parking_lots IS '駐車場の基本情報（名称、住所、電話番号、収容台数、料金、特徴概要、サイズ制限、車種、最寄り駅、利用状況など）を格納するテーブル。貸出タイプ、特徴、対応車種、Google Maps情報は関連テーブルで詳細管理。';
-- カラムコメント
COMMENT ON COLUMN t_parking_lots.parking_lot_id IS '駐車場の一意識別子（形式: P-XXXXXX, XXXXXXは6桁のランダムかつ一意な数字、例: P-000007）';
COMMENT ON COLUMN t_parking_lots.owner_id IS '関連するオーナーID（形式: owner_XXXXXX）';
COMMENT ON COLUMN t_parking_lots.parking_lot_name IS '駐車場の名称';
COMMENT ON COLUMN t_parking_lots.postal_code IS '駐車場の郵便番号（例: 123-4567）';
COMMENT ON COLUMN t_parking_lots.prefecture IS '駐車場の都道府県';
COMMENT ON COLUMN t_parking_lots.city IS '駐車場の市区町村';
COMMENT ON COLUMN t_parking_lots.address_detail IS '駐車場の番地・建物名';
COMMENT ON COLUMN t_parking_lots.phone_number IS '駐車場管理者または管理会社の電話番号（一意）';
COMMENT ON COLUMN t_parking_lots.capacity IS '駐車場の収容台数';
COMMENT ON COLUMN t_parking_lots.available_capacity IS '駐車場の現在の空き台数（可NULL、負の値は不可）';
COMMENT ON COLUMN t_parking_lots.rental_type IS '貸出タイプ（時間単位または日間単位、t_parking_rental_typesと関連）';
COMMENT ON COLUMN t_parking_lots.charge IS '料金詳細';
COMMENT ON COLUMN t_parking_lots.features_tip IS '駐車場の特徴概要（m_parking_featuresと関連、可NULL）';
COMMENT ON COLUMN t_parking_lots.length_limit IS '車両の長さ制限（cm単位、可NULL）';
COMMENT ON COLUMN t_parking_lots.width_limit IS '車両の幅制限（cm単位、可NULL）';
COMMENT ON COLUMN t_parking_lots.height_limit IS '車両の高さ制限（cm単位、可NULL）';
COMMENT ON COLUMN t_parking_lots.weight_limit IS '車両の重量制限（kg単位、可NULL）';
COMMENT ON COLUMN t_parking_lots.car_height_limit IS '車高制限（選択肢：制限なし、150cm以下など）';
COMMENT ON COLUMN t_parking_lots.tire_width_limit IS 'タイヤ幅制限（選択肢：制限なし）';
COMMENT ON COLUMN t_parking_lots.vehicle_type IS '駐車場の主要な車種（m_parking_vehicle_typesと関連）';
COMMENT ON COLUMN t_parking_lots.nearest_station IS '最寄り駅（例: 東京駅）';
COMMENT ON COLUMN t_parking_lots.status IS '駐車場の状態（アクティブまたは停止中）';
COMMENT ON COLUMN t_parking_lots.start_date IS '駐車場の利用開始日';
COMMENT ON COLUMN t_parking_lots.end_date IS '駐車場の利用停止日';
COMMENT ON COLUMN t_parking_lots.end_start_datetime IS '利用停止の開始日時';
COMMENT ON COLUMN t_parking_lots.end_end_datetime IS '利用停止の終了日時';
COMMENT ON COLUMN t_parking_lots.end_reason IS '利用停止の理由（メンテナンス・維持、その他）';
COMMENT ON COLUMN t_parking_lots.end_reason_detail IS '停止理由が「その他」の場合の詳細';
COMMENT ON COLUMN t_parking_lots.notes IS '駐車場の注意事項';
COMMENT ON COLUMN t_parking_lots.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_parking_lots.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_t_parking_lots_owner_id ON t_parking_lots(owner_id);
CREATE INDEX idx_t_parking_lots_phone_number ON t_parking_lots(phone_number);
CREATE INDEX idx_t_parking_lots_status ON t_parking_lots(status);
CREATE INDEX idx_t_parking_lots_prefecture_city ON t_parking_lots(prefecture, city);
CREATE INDEX idx_t_parking_lots_available_capacity ON t_parking_lots(available_capacity);


-- 2. 駐車場Google Maps関連情報テーブル
-- 論理名: 駐車場Google Maps関連情報テーブル
-- 物理名: t_parking_google_maps
CREATE TABLE t_parking_google_maps (
    -- 論理名: Google Maps情報ID
    -- 物理名: google_maps_id
    google_maps_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: 駐車場ID
    -- 物理名: parking_lot_id
    parking_lot_id VARCHAR(37) NOT NULL,
    -- 論理名: 緯度
    -- 物理名: latitude
    latitude DECIMAL(9, 6),
    -- 論理名: 経度
    -- 物理名: longitude
    longitude DECIMAL(9, 6),
    -- 論理名: Google Place ID
    -- 物理名: place_id
    place_id VARCHAR(100),
    -- 論理名: ズームレベル
    -- 物理名: zoom_level
    zoom_level INTEGER,
    -- 論理名: 地図タイプ
    -- 物理名: map_type
    map_type VARCHAR(20),
    -- 論理名: Google Maps URL
    -- 物理名: google_maps_url
    google_maps_url TEXT,
    -- 論理名: Google Maps埋め込みリンク
    -- 物理名: google_maps_embed
    google_maps_embed TEXT,
    -- 論理名: 説明
    -- 物理名: description
    description TEXT,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_latitude CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    -- CONSTRAINT check_longitude CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    -- CONSTRAINT check_zoom_level CHECK (zoom_level IS NULL OR (zoom_level BETWEEN 0 AND 21)),
    -- CONSTRAINT check_map_type CHECK (map_type IS NULL OR map_type IN ('roadmap', 'satellite', 'hybrid', 'terrain')),
    -- CONSTRAINT fk_t_parking_google_maps_parking_lot_id FOREIGN KEY (parking_lot_id) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
    CONSTRAINT pk_t_parking_google_maps PRIMARY KEY (google_maps_id)
);
-- テーブルコメント
COMMENT ON TABLE t_parking_google_maps IS '駐車場のGoogle Maps関連情報（緯度・経度、Place ID、ズームレベル、地図タイプ、URL、埋め込みリンクなど）を管理するテーブル。1つの駐車場IDに対し複数のGoogle Maps情報を関連付け可能。';
-- カラムコメント
COMMENT ON COLUMN t_parking_google_maps.google_maps_id IS 'Google Maps情報の一意識別子（UUID v4）';
COMMENT ON COLUMN t_parking_google_maps.parking_lot_id IS '関連する駐車場ID（形式: P-XXXXXX）';
COMMENT ON COLUMN t_parking_google_maps.latitude IS '駐車場の緯度（Google Maps用、可NULL）';
COMMENT ON COLUMN t_parking_google_maps.longitude IS '駐車場の経度（Google Maps用、可NULL）';
COMMENT ON COLUMN t_parking_google_maps.place_id IS 'Google MapsのPlace ID（場所特定用、可NULL）';
COMMENT ON COLUMN t_parking_google_maps.zoom_level IS '地図のズームレベル（0～21、可NULL）';
COMMENT ON COLUMN t_parking_google_maps.map_type IS '地図のタイプ（roadmap, satellite, hybrid, terrain、可NULL）';
COMMENT ON COLUMN t_parking_google_maps.google_maps_url IS 'Google MapsのURL（可NULL）';
COMMENT ON COLUMN t_parking_google_maps.google_maps_embed IS 'Google Mapsの埋め込みリンク（可NULL）';
COMMENT ON COLUMN t_parking_google_maps.description IS 'Google Maps情報の説明（可NULL）';
COMMENT ON COLUMN t_parking_google_maps.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_parking_google_maps.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_t_parking_google_maps_parking_lot_id ON t_parking_google_maps(parking_lot_id);

-- 3. 駐車場貸出タイプテーブル
-- 論理名: 駐車場貸出タイプテーブル
-- 物理名: t_parking_rental_types
CREATE TABLE t_parking_rental_types (
    -- 論理名: 貸出タイプID
    -- 物理名: rental_type_id
    rental_type_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: 駐車場ID
    -- 物理名: parking_lot_id
    parking_lot_id VARCHAR(37) NOT NULL,
    -- 論理名: 貸出タイプ
    -- 物理名: rental_type
    rental_type VARCHAR(20) NOT NULL,
    -- 論理名: 貸出値
    -- 物理名: rental_value
    rental_value VARCHAR(50) NOT NULL,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_rental_type CHECK (rental_type IN ('時間単位', '日間単位')),
    -- CONSTRAINT check_rental_value CHECK (
    --     (rental_type = '時間単位' AND rental_value IN ('15分', '30分', '1時間')) OR
    --     (rental_type = '日間単位' AND rental_value IN ('1日', '2日', '1週間', '1ヶ月'))
    -- ),
    -- CONSTRAINT fk_t_parking_rental_types_parking_lot_id FOREIGN KEY (parking_lot_id) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
    CONSTRAINT unique_t_parking_rental_types_parking_lot_id_rental_type UNIQUE (parking_lot_id, rental_type),
    CONSTRAINT pk_t_parking_rental_types PRIMARY KEY (rental_type_id)
);
-- テーブルコメント
COMMENT ON TABLE t_parking_rental_types IS '駐車場の貸出タイプ（時間単位または日間単位）とその値（例: 15分、1日）を管理するテーブル。同一駐車場IDに対し貸出タイプは一意。';
-- カラムコメント
COMMENT ON COLUMN t_parking_rental_types.rental_type_id IS '貸出タイプの一意識別子（UUID v4）';
COMMENT ON COLUMN t_parking_rental_types.parking_lot_id IS '関連する駐車場ID（形式: P-XXXXXX）';
COMMENT ON COLUMN t_parking_rental_types.rental_type IS '貸出タイプ（時間単位または日間単位、t_parking_lots.rental_typeと関連）';
COMMENT ON COLUMN t_parking_rental_types.rental_value IS '貸出タイプの値（例: 15分、1日）';
COMMENT ON COLUMN t_parking_rental_types.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_parking_rental_types.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_t_parking_rental_types_parking_lot_id ON t_parking_rental_types(parking_lot_id);

-- 4. 駐車場対応車種テーブル
-- 論理名: 駐車場対応車種テーブル
-- 物理名: m_parking_vehicle_types
CREATE TABLE m_parking_vehicle_types (
    -- 論理名: 車種ID
    -- 物理名: vehicle_type_id
    vehicle_type_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: 駐車場ID
    -- 物理名: parking_lot_id
    parking_lot_id VARCHAR(37) NOT NULL,
    -- 論理名: 車種
    -- 物理名: vehicle_type
    vehicle_type VARCHAR(20) NOT NULL,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_vehicle_type CHECK (vehicle_type IN ('オートバイ', '軽自動車', 'ワンボックスカー', '中型車', '大型車', 'トラック')),
    -- CONSTRAINT fk_m_parking_vehicle_types_parking_lot_id FOREIGN KEY (parking_lot_id) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
    CONSTRAINT unique_m_parking_vehicle_types_parking_lot_id_vehicle_type UNIQUE (parking_lot_id, vehicle_type),
    CONSTRAINT pk_m_parking_vehicle_types PRIMARY KEY (vehicle_type_id)
);
-- テーブルコメント
-- 修正：表コメントを正しい内容に修正
COMMENT ON TABLE m_parking_vehicle_types IS '駐車場の対応車種（オートバイ、軽自動車など）を管理するテーブル。同一駐車場IDに対し車種は一意。';
-- カラムコメント
COMMENT ON COLUMN m_parking_vehicle_types.vehicle_type_id IS '車種の一意識別子（UUID v4）';
-- 未設定の場合、全ての駐車場に適用され、
-- 設定されている場合、特定の駐車場または特例に使用されます。
COMMENT ON COLUMN m_parking_vehicle_types.parking_lot_id IS '関連する駐車場ID（形式: P-XXXXXX）';
COMMENT ON COLUMN m_parking_vehicle_types.vehicle_type IS '対応車種（オートバイ、軽自動車など、t_parking_lots.vehicle_typeと関連）';
COMMENT ON COLUMN m_parking_vehicle_types.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN m_parking_vehicle_types.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_m_parking_vehicle_types_parking_lot_id ON m_parking_vehicle_types(parking_lot_id);

-- 5. 駐車場特徴テーブル
-- 論理名: 駐車場特徴テーブル
-- 物理名: m_parking_features
CREATE TABLE m_parking_features (
    -- 論理名: 特徴ID
    -- 物理名: feature_id
    feature_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: 駐車場ID
    -- 物理名: parking_lot_id
    parking_lot_id VARCHAR(37) NOT NULL,
    -- 論理名: 特徴タイプ
    -- 物理名: feature_type
    feature_type VARCHAR(50) NOT NULL,
    -- 論理名: 特徴値
    -- 物理名: feature_value
    -- 修正：特徴値HIGHを特徴値に修正
    feature_value TEXT NOT NULL,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_feature_type CHECK (feature_type IN (
    --     '営業時間', '予約タイプ', '最大料金', '再入庫', '当日予約', 'シェアゲート', '照明', 'セキュリティ'
    -- )),
    -- CONSTRAINT check_feature_value CHECK (
    --     (feature_type = '営業時間' AND feature_value IN ('24時間営業', '時間制限あり')) OR
    --     (feature_type = '予約タイプ' AND feature_value IN ('日貸しのみ', '時間貸し可能')) OR
    --     (feature_type = '最大料金' AND feature_value IN ('当日最大料金', '24時間最大料金', '最大料金なし')) OR
    --     (feature_type = '再入庫' AND feature_value IN ('再入庫可能', '再入庫不可')) OR
    --     (feature_type = '当日予約' AND feature_value IN ('可能', '不可')) OR
    --     (feature_type = 'シェアゲート' AND feature_value IN ('あり', 'なし')) OR
    --     (feature_type = '照明' AND feature_value IN ('あり', 'なし')) OR
    --     (feature_type = 'セキュリティ' AND feature_value IN ('カメラあり', 'ゲートあり', 'セキュリティなし'))
    -- ),
    -- CONSTRAINT fk_m_parking_features_parking_lot_id FOREIGN KEY (parking_lot_id) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
    CONSTRAINT unique_m_parking_features_parking_lot_id_feature_type UNIQUE (parking_lot_id, feature_type),
    CONSTRAINT pk_m_parking_features PRIMARY KEY (feature_id)
);
-- テーブルコメント
COMMENT ON TABLE m_parking_features IS '駐車場の特徴（営業時間、予約タイプ、最大料金、再入庫など）を個別に管理するテーブル。同一駐車場IDに対し特徴タイプは一意。';
-- カラムコメント
COMMENT ON COLUMN m_parking_features.feature_id IS '特徴の一意識別子（UUID v4）';
COMMENT ON COLUMN m_parking_features.parking_lot_id IS '関連する駐車場ID（形式: P-XXXXXX）';
COMMENT ON COLUMN m_parking_features.feature_type IS '特徴の種類（例: 営業時間、予約タイプなど）';
COMMENT ON COLUMN m_parking_features.feature_value IS '特徴の値（例: 24時間営業、再入庫可能など）';
COMMENT ON COLUMN m_parking_features.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN m_parking_features.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_m_parking_features_parking_lot_id ON m_parking_features(parking_lot_id);
CREATE INDEX idx_m_parking_features_feature_type ON m_parking_features(feature_type);

-- 1. 予約情報テーブル
-- 論理名: 予約情報テーブル
-- 物理名: t_reservations
CREATE TABLE t_reservations (
    -- 論理名: 予約ID
    -- 物理名: reservation_id
    reservation_id VARCHAR(37) NOT NULL,
    -- 論理名: ユーザーID
    -- 物理名: user_id
    user_id VARCHAR(37) NOT NULL,
    -- 論理名: 駐車場ID
    -- 物理名: parking_lot_id
    parking_lot_id VARCHAR(37) NOT NULL,
    -- 論理名: 予約開始日時
    -- 物理名: start_datetime
    start_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    -- 論理名: 予約終了日時
    -- 物理名: end_datetime
    end_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    -- 論理名: ステータス
    -- 物理名: status
    status VARCHAR(2) NOT NULL,
    -- 論理名: キャンセル理由
    -- 物理名: cancel_reason
    cancel_reason TEXT,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_datetime_order CHECK (start_datetime < end_datetime),
    -- CONSTRAINT check_status CHECK (status IN ('0', '1', '2')),
    -- CONSTRAINT check_cancel_reason CHECK (
    --     (status = '2' AND cancel_reason IS NOT NULL) OR
    --     (status != '2' AND cancel_reason IS NULL)
    -- ),
    -- CONSTRAINT fk_t_reservations_user_id FOREIGN KEY (user_id) REFERENCES m_users(user_id) ON DELETE CASCADE,
    -- CONSTRAINT fk_t_reservations_parking_lot_id FOREIGN KEY (parking_lot_id) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
    CONSTRAINT pk_t_reservations PRIMARY KEY (reservation_id)
);
-- テーブルコメント
COMMENT ON TABLE t_reservations IS '駐車場の予約情報（利用者、駐車場、予約日時、ステータスなど）を管理するテーブル。1つの利用者や駐車場に対し複数の予約を関連付け可能。';
-- カラムコメント
COMMENT ON COLUMN t_reservations.reservation_id IS '予約の一意識別子（形式: P + yyyyMMddHHmmss + ミリ秒タイムスタンプ、例: P202505041928311234567）';
COMMENT ON COLUMN t_reservations.user_id IS '予約したユーザーのID（形式: user_XXXXXX）';
COMMENT ON COLUMN t_reservations.parking_lot_id IS '予約対象の駐車場ID（形式: P-XXXXXX）';
COMMENT ON COLUMN t_reservations.start_datetime IS '予約の開始日時';
COMMENT ON COLUMN t_reservations.end_datetime IS '予約の終了日時';
COMMENT ON COLUMN t_reservations.status IS '予約のステータス（0: 予約可, 1: 予約中, 2: 承認ずみ（または予約済み）, 3: キャンセル, 4: 完了）';
COMMENT ON COLUMN t_reservations.cancel_reason IS 'キャンセル理由（ステータスがキャンセルの場合必須、可NULL）';
COMMENT ON COLUMN t_reservations.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_reservations.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_t_reservations_user_id ON t_reservations(user_id);
CREATE INDEX idx_t_reservations_parking_lot_id ON t_reservations(parking_lot_id);
CREATE INDEX idx_t_reservations_status ON t_reservations(status);
CREATE INDEX idx_t_reservations_start_end_datetime ON t_reservations(start_datetime, end_datetime);

-- 2. 予約詳細テーブル
-- 論理名: 予約詳細テーブル
-- 物理名: t_reservation_details
CREATE TABLE t_reservation_details (
    -- 論理名: 詳細ID
    -- 物理名: detail_id
    detail_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: 予約ID
    -- 物理名: reservation_id
    reservation_id VARCHAR(37) NOT NULL,
    -- 論理名: エリア
    -- 物理名: area
    area VARCHAR(50),
    -- 論理名: 料金
    -- 物理名: amount
    amount DECIMAL(10, 2) NOT NULL,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_amount CHECK (amount >= 0),
    -- CONSTRAINT fk_t_reservation_details_reservation_id FOREIGN KEY (reservation_id) REFERENCES t_reservations(reservation_id) ON DELETE CASCADE,
    CONSTRAINT pk_t_reservation_details PRIMARY KEY (detail_id)
);
-- テーブルコメント
COMMENT ON TABLE t_reservation_details IS '予約の詳細情報（エリア、料金など）を管理するテーブル。1つの予約に対し複数の詳細情報を関連付け可能。';
-- カラムコメント
COMMENT ON COLUMN t_reservation_details.detail_id IS '予約詳細の一意識別子（UUID v4）';
COMMENT ON COLUMN t_reservation_details.reservation_id IS '関連する予約ID';
COMMENT ON COLUMN t_reservation_details.area IS 'エリア（例: 品川、可NULL）';
COMMENT ON COLUMN t_reservation_details.amount IS '予約金額（円）';
COMMENT ON COLUMN t_reservation_details.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_reservation_details.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_t_reservation_details_reservation_id ON t_reservation_details(reservation_id);

-- 3. 利用情報テーブル
-- 論理名: 利用情報テーブル
-- 物理名: t_usage_info
CREATE TABLE t_usage_info (
    -- 論理名: 利用情報ID
    -- 物理名: usage_id
    usage_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: 予約ID
    -- 物理名: reservation_id
    reservation_id VARCHAR(37) NOT NULL,
    -- 論理名: 利用車両
    -- 物理名: vehicle_name
    vehicle_name VARCHAR(100),
    -- 論理名: 車種名
    -- 物理名: vehicle_type_name
    vehicle_type_name VARCHAR(50),
    -- 論理名: ナンバー
    -- 物理名: license_plate
    license_plate VARCHAR(20),
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT fk_t_usage_info_reservation_id FOREIGN KEY (reservation_id) REFERENCES t_reservations(reservation_id) ON DELETE CASCADE,
    CONSTRAINT unique_t_usage_info_reservation_id UNIQUE (reservation_id),
    CONSTRAINT pk_t_usage_info PRIMARY KEY (usage_id)
);
-- テーブルコメント
COMMENT ON TABLE t_usage_info IS '予約ごとの利用情報（利用車両、車種名、ナンバーなど）を管理するテーブル。1つの予約に対し1つの利用情報を関連付け。';
-- カラムコメント
COMMENT ON COLUMN t_usage_info.usage_id IS '利用情報の一意識別子（UUID v4）';
COMMENT ON COLUMN t_usage_info.reservation_id IS '関連する予約ID';
COMMENT ON COLUMN t_usage_info.vehicle_name IS '利用車両の名称（例: トヨタプリウス、可NULL）';
COMMENT ON COLUMN t_usage_info.vehicle_type_name IS '車種名（例: セダン、可NULL）';
COMMENT ON COLUMN t_usage_info.license_plate IS '車両のナンバープレート（例: 0000、可NULL）';
COMMENT ON COLUMN t_usage_info.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_usage_info.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_t_usage_info_reservation_id ON t_usage_info(reservation_id);

-- 4. お気に入りテーブル
-- 論理名: お気に入りテーブル
-- 物理名: t_favorites
CREATE TABLE t_favorites (
    -- 論理名: お気に入りID
    -- 物理名: favorite_id
    favorite_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: ユーザーID
    -- 物理名: user_id
    user_id VARCHAR(37) NOT NULL,
    -- 論理名: 駐車場ID
    -- 物理名: parking_lot_id
    parking_lot_id VARCHAR(37) NOT NULL,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT fk_t_favorites_user_id FOREIGN KEY (user_id) REFERENCES m_users(user_id) ON DELETE CASCADE,
    -- CONSTRAINT fk_t_favorites_parking_lot_id FOREIGN KEY (parking_lot_id) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
    CONSTRAINT unique_t_favorites_user_id_parking_lot_id UNIQUE (user_id, parking_lot_id),
    CONSTRAINT pk_t_favorites PRIMARY KEY (favorite_id)
);
-- テーブルコメント
COMMENT ON TABLE t_favorites IS 'ユーザーがお気に入りに登録した駐車場を管理するテーブル。同一ユーザーと駐車場の組み合わせは一意。';
-- カラムコメント
COMMENT ON COLUMN t_favorites.favorite_id IS 'お気に入りの一意識別子（UUID v4）';
COMMENT ON COLUMN t_favorites.user_id IS 'お気に入りに登録したユーザーのID（形式: user_XXXXXX）';
COMMENT ON COLUMN t_favorites.parking_lot_id IS 'お気に入りに登録した駐車場ID（形式: P-XXXXXX）';
COMMENT ON COLUMN t_favorites.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_favorites.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_t_favorites_user_id ON t_favorites(user_id);
CREATE INDEX idx_t_favorites_parking_lot_id ON t_favorites(parking_lot_id);

-- 5. 入出庫状況テーブル
-- 論理名: 入出庫状況テーブル
-- 物理名: t_parking_status
CREATE TABLE t_parking_status (
    -- 論理名: 入出庫状況ID
    -- 物理名: status_id
    status_id VARCHAR(37) NOT NULL DEFAULT uuid_generate_v4(),
    -- 論理名: 予約ID
    -- 物理名: reservation_id
    reservation_id VARCHAR(37) NOT NULL,
    -- 論理名: 駐車場ID
    -- 物理名: parking_lot_id
    parking_lot_id VARCHAR(37) NOT NULL,
    -- 論理名: 入庫状態
    -- 物理名: entry_status
    entry_status VARCHAR(20) NOT NULL,
    -- 論理名: 出庫状態
    -- 物理名: exit_status
    exit_status VARCHAR(20) NOT NULL,
    -- 論理名: 入庫時間
    -- 物理名: entry_datetime
    entry_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: 出庫時間
    -- 物理名: exit_datetime
    exit_datetime TIMESTAMP WITH TIME ZONE,
    -- 論理名: 作成日時
    -- 物理名: created_datetime
    created_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- 論理名: 更新日時
    -- 物理名: updated_datetime
    updated_datetime TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINT check_entry_status CHECK (entry_status IN ('未入庫', '入庫済み')),
    -- CONSTRAINT check_exit_status CHECK (exit_status IN ('未出庫', '出庫済み')),
    -- CONSTRAINT check_datetime_order CHECK (
    --     (entry_datetime IS NULL OR exit_datetime IS NULL) OR
    --     (entry_datetime <= exit_datetime)
    -- ),
    -- CONSTRAINT check_entry_datetime CHECK (
    --     (entry_status = '未入庫' AND entry_datetime IS NULL) OR
    --     (entry_status = '入庫済み' AND entry_datetime IS NOT NULL)
    -- ),
    -- CONSTRAINT check_exit_datetime CHECK (
    --     (exit_status = '未出庫' AND exit_datetime IS NULL) OR
    --     (exit_status = '出庫済み' AND exit_datetime IS NOT NULL)
    -- ),
    -- CONSTRAINT fk_t_parking_status_reservation_id FOREIGN KEY (reservation_id) REFERENCES t_reservations(reservation_id) ON DELETE CASCADE,
    -- CONSTRAINT fk_t_parking_status_parking_lot_id FOREIGN KEY (parking_lot_id) REFERENCES t_parking_lots(parking_lot_id) ON DELETE CASCADE,
    CONSTRAINT unique_t_parking_status_reservation_id UNIQUE (reservation_id),
    CONSTRAINT pk_t_parking_status PRIMARY KEY (status_id)
);
-- テーブルコメント
COMMENT ON TABLE t_parking_status IS '予約ごとの入出庫状況（予約ID、駐車場ID、入庫状態、出庫状態、入庫時間、出庫時間）を管理するテーブル。予約IDはreservation_idフィールドで管理され、t_reservationsと関連付け。1つの予約に対し1つの入出庫状況を関連付け。';
-- カラムコメント
COMMENT ON COLUMN t_parking_status.status_id IS '入出庫状況の一意識別子（UUID v4）';
COMMENT ON COLUMN t_parking_status.reservation_id IS '関連する予約ID（t_reservations.reservation_idを参照、形式: P + yyyyMMddHHmmss + ミリ秒タイムスタンプ）';
COMMENT ON COLUMN t_parking_status.parking_lot_id IS '予約対象の駐車場ID（形式: P-XXXXXX）';
COMMENT ON COLUMN t_parking_status.entry_status IS '入庫状態（未入庫または入庫済み）';
COMMENT ON COLUMN t_parking_status.exit_status IS '出庫状態（未出庫または出庫済み）';
COMMENT ON COLUMN t_parking_status.entry_datetime IS '入庫時間（可NULL、入庫済みの場合は必須）';
COMMENT ON COLUMN t_parking_status.exit_datetime IS '出庫時間（可NULL、出庫済みの場合は必須）';
COMMENT ON COLUMN t_parking_status.created_datetime IS 'レコードの作成日時';
COMMENT ON COLUMN t_parking_status.updated_datetime IS 'レコードの最終更新日時';
-- インデックス作成
CREATE INDEX idx_t_parking_status_reservation_id ON t_parking_status(reservation_id);
CREATE INDEX idx_t_parking_status_parking_lot_id ON t_parking_status(parking_lot_id);
CREATE INDEX idx_t_parking_status_entry_exit_status ON t_parking_status(entry_status, exit_status);