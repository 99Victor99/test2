-- 初始化数据库脚本

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    uid SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    age INTEGER NOT NULL CHECK (age >= 0 AND age <= 150),
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建用户信息表
CREATE TABLE IF NOT EXISTS user_info (
    uid INTEGER PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
    email VARCHAR(255),
    ip INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建用户地址表
CREATE TABLE IF NOT EXISTS user_address (
    uid INTEGER PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
    home TEXT,
    brand INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_user_info_email ON user_info(email);

-- 插入测试数据
INSERT INTO users (name, age, email) VALUES 
    ('张三', 25, 'zhangsan@example.com'),
    ('李四', 30, 'lisi@example.com'),
    ('王五', 28, 'wangwu@example.com')
ON CONFLICT (name) DO NOTHING;

-- 插入用户信息测试数据
INSERT INTO user_info (uid, email, ip) VALUES 
    (1, 'zhangsan@example.com', '192.168.1.1'),
    (2, 'lisi@example.com', '192.168.1.2'),
    (3, 'wangwu@example.com', '192.168.1.3')
ON CONFLICT (uid) DO NOTHING;

-- 插入用户地址测试数据
INSERT INTO user_address (uid, home, brand) VALUES 
    (1, '北京市朝阳区', 1),
    (2, '上海市浦东新区', 2),
    (3, '广州市天河区', 3)
ON CONFLICT (uid) DO NOTHING;
