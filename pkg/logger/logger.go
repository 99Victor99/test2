package logger

import (
	"log/slog"
	"os"
)

// Logger 日志接口
type Logger interface {
	Debug(msg string, args ...interface{})
	Info(msg string, args ...interface{})
	Warn(msg string, args ...interface{})
	Error(msg string, args ...interface{})
	Fatal(msg string, args ...interface{})
}

// SlogLogger slog 实现
type SlogLogger struct {
	logger *slog.Logger
}

// New 创建新的日志器
func New(level string) Logger {
	var logLevel slog.Level
	switch level {
	case "debug":
		logLevel = slog.LevelDebug
	case "info":
		logLevel = slog.LevelInfo
	case "warn":
		logLevel = slog.LevelWarn
	case "error":
		logLevel = slog.LevelError
	default:
		logLevel = slog.LevelInfo
	}

	opts := &slog.HandlerOptions{
		Level: logLevel,
	}

	handler := slog.NewJSONHandler(os.Stdout, opts)
	logger := slog.New(handler)

	return &SlogLogger{
		logger: logger,
	}
}

// Debug 调试日志
func (l *SlogLogger) Debug(msg string, args ...interface{}) {
	l.logger.Debug(msg, args...)
}

// Info 信息日志
func (l *SlogLogger) Info(msg string, args ...interface{}) {
	l.logger.Info(msg, args...)
}

// Warn 警告日志
func (l *SlogLogger) Warn(msg string, args ...interface{}) {
	l.logger.Warn(msg, args...)
}

// Error 错误日志
func (l *SlogLogger) Error(msg string, args ...interface{}) {
	l.logger.Error(msg, args...)
}

// Fatal 致命错误日志
func (l *SlogLogger) Fatal(msg string, args ...interface{}) {
	l.logger.Error(msg, args...)
	os.Exit(1)
}
