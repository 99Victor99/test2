package config

import (
	"os"
	"strconv"
)

// Config 应用配置
type Config struct {
	Port        int    `json:"port"`
	Environment string `json:"environment"`
	LogLevel    string `json:"log_level"`
	DatabaseURL string `json:"database_url"`

	// Redis 配置
	RedisAddr     string `json:"redis_addr"`
	RedisPassword string `json:"redis_password"`
	RedisDB       int    `json:"redis_db"`

	// JWT 配置
	JWTSecret string `json:"jwt_secret"`

	// 外部服务配置
	GoodsServiceAddr  string `json:"goods_service_addr"`
	OrdersServiceAddr string `json:"orders_service_addr"`
}

// Load 加载配置
func Load() *Config {
	return &Config{
		Port:        getEnvAsInt("PORT", 8080),
		Environment: getEnv("ENVIRONMENT", "development"),
		LogLevel:    getEnv("LOG_LEVEL", "info"),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://localhost/users_db?sslmode=disable"),

		RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       getEnvAsInt("REDIS_DB", 0),

		JWTSecret: getEnv("JWT_SECRET", "your-secret-key"),

		GoodsServiceAddr:  getEnv("GOODS_SERVICE_ADDR", "localhost:8081"),
		OrdersServiceAddr: getEnv("ORDERS_SERVICE_ADDR", "localhost:8082"),
	}
}

// getEnv 获取环境变量，如果不存在则返回默认值
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsInt 获取环境变量并转换为整数
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
